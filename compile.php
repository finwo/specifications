<?php

if(!defined('DS')) define('DS',DIRECTORY_SEPARATOR);
if(!defined('EOL')) define('EOL',"\n");
require(__DIR__.DS.'vendor'.DS.'autoload.php');
$params = array();
@array_shift($argv);
@parse_str(@implode('&',$argv), $params);

function perror($msg=null) {
    if(is_null($msg)) exit(1);
    if(is_string($msg)) {
        echo $msg, PHP_EOL;
    } else {
        try {
            echo json_encode($msg, JSON_PRETTY_PRINT), PHP_EOL;
        } catch(Exception $e) {
            // Do nothing
        }
    }
    exit(1);
}

function flatten( $data, $prefix = '', &$output = [] ) {
    foreach($data as $key => $value) {
        if(is_array($value)) { pack($value,$prefix.$key.'.',$output); }
        else { $output[$prefix.$key] = $value; }
    }
    return $output;
}
function unflatten( $flatArray, &$output = [] ) {
    static $accessor = null;
    $accessor = $accessor ?: new \Finwo\PropertyAccessor\PropertyAccessor(true);
    if(is_string($flatArray)) {
        $flatArray = str_replace(["\r\n","\r"],"\n",$flatArray);
        $flatArray = array_filter(explode("\n",$flatArray));
        $flatArray = array_map(function($line){return array_map('trim',explode(':',$line));},$flatArray);
        $flatArray = array_map(function($kv){$kv[0]=strtolower($kv[0]);return $kv;},$flatArray);
        $flatArray = array_reduce($flatArray,function($acc,$kv){$acc[$kv[0]]=$kv[1];return $acc;},[]);
    }
    foreach ($flatArray as $key => $value ) $accessor->set($output,$key,$value,'.');
    return $output;
}

function fcopy($src,$dst=null) {
    if(is_null($dst)) $dst = fopen('php://temp','c+');
    while(!feof($src)) fwrite($dst,fread($src,1024)?:'');
    return $dst;
}

class Pipe {
    protected $processor = null;
    protected $next      = null;
    protected $writable  = true;
    protected $userdata  = null;
    public function __construct( $processor, Pipe $next = null ) {
        if(is_array($processor)) {
            $this->processor = array_shift($processor);
            if(count($processor)) $this->next = new Pipe($processor);
        } else {
            $this->processor = $processor;
            $this->next      = $next;
        }
    }
    public function write( $chunk ) {
        if(!$this->writable) return false;
        if(is_resource($this->processor)&&$chunk) return fwrite($this->processor,$chunk);
        if(is_callable($this->processor)) return call_user_func_array($this->processor,[$chunk,$this->next,&$this->userdata]);
        return false;
    }
    public function end( $chunk = null ) {
        if(!is_null($chunk)) $this->write($chunk);
        $this->write(null);
        if(is_resource($this->processor)) $this->processor = fclose($this->processor);
        if($this->next instanceof Pipe) $this->next->end();
    }
}
function normalize_newlines( $chunk, Pipe $next ) {
    if(is_null($chunk)) return;
    $next->write(str_replace(["\r\n","\r"],EOL,$chunk));
}
function inclusions( $chunk, Pipe $next ) {
    if(is_null($chunk)) return;
    $indent = strlen(rtrim($chunk))-strlen(trim($chunk));
    if(substr($chunk,$indent,1)=='<') {
        $fd = fopen('src'.DS.substr(trim($chunk),1).'.spec','r');
        while(!feof($fd)) $next->write(str_repeat(' ',$indent).fgets($fd));
        fclose($fd);
    } else {
        $next->write($chunk);
    }
}
function to_chars( $chunk, Pipe $next ) {
    if(is_null($chunk)) return;
    foreach (str_split($chunk) as $chr) $next->write($chr);
}
function group_symbols( $char, Pipe $next, &$data ) {
    $data = $data ?: '';
    switch($char) {
        case '`':
            $data .= $char;
            break;
        default:
            if(strlen($data)) $next->write($data);
            $data = '';
            $next->write($char);
    }
}
function group_unbreakables( $symbol, Pipe $next, &$data ) {
    $data = $data ?: [];
    $cnt  = count($data);
    $top  = $cnt ? $data[$cnt-1] : null;
    switch($symbol) {
        case '```':
        case '`':
        case '"':
        case "'":
            if($cnt) {
                if($top[0]==$symbol) {
                    $me = array_pop($data);
                    if($cnt==1) {
                        $next->write($me[1].$symbol.EOL);
                    } else {
                        $data[$cnt-2][1] .= $me[1].$symbol;
                    }
                } else {
                    $data[] = [$symbol,$symbol];
                }
            } else {
                $data[] = [$symbol,$symbol];
            }
            break;
        default:
            if($cnt) {
                $data[$cnt-1][1] .= $symbol;
            } else {
                $next->write($symbol.EOL);
            }
            break;
    }
}

// Make sure we get the minimum params
if(!isset($params['spec'])) perror('Spec missing from the parameters');
$spec = $params['spec'];

// Ensure the said spec has a src
if(!file_exists('src'.DS.$spec.'.spec')) perror('Given source does not exist');
$filename = implode(DS,[__DIR__,'src',$spec.'.spec']);

// Fetch the file's headers
$fd       = fopen($filename,'r+');
$headers  = '';
while(!feof($fd)) {
    $line = trim(fgets($fd));
    if(!$line) break;
    $headers .= $line . "\n";
}
$headers = unflatten($headers);

// Build the processing pipe
$pipes = [
    "txt" => new Pipe([
        'normalize_newlines',
        'inclusions',
        'to_chars',
        'group_symbols',
        'group_unbreakables',
        fopen('spec'.DS.'spec'.$spec.'.txt','w+'),
    ]),
];

// Run data through the pipes
while(!feof($fd)) {
    $line = fgets($fd);
    foreach ($pipes as $pipe)
        $pipe->write($line);
}

// Close the pipes
foreach ($pipes as $pipe)
    $pipe->end();
