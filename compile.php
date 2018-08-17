<?php

if(!defined('DS')) define('DS',DIRECTORY_SEPARATOR);
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
    foreach ($flatArray as $key => $value ) $accessor->set($output,$key,$value,'.');
    return $output;
}

function configFile( $file, &$output = [] ) {
    $fd = null;
    if(is_array($file)) $file = implode(DS,$file);
    if(is_string($file) && file_exists($file)) { $fd = fopen($file,'r'); $file = null; }
    if(is_string($file)) {
        $fd = fopen('php://temp','r+');
        fwrite($fd,$file);
        fseek($fd,0);
        $file = null;
    }
    if(!$fd) return null;
    while(!feof($fd)) {                                  // Loop until we're out of file
        $line = fgets($fd);                              // Fetch the line we're about to process
        $line = @array_shift(str_getcsv($line,'#'));     // Strip comments
        $line = trim($line);                             // Trim line (we don't care about whitespace)
        if(strlen($line)==0) continue;                   // Blank line = skip
        $line = array_map('trim',str_getcsv($line,':')); // Split key & value
        if(count($line)!=2) continue;                    // Only 1 key & 1 value supported
        $output[strtolower($line[0])]=$line[1];          // Flat keys
    }
    fclose($fd);
    return $output;
}

function fcopy($src,$dst=null) {
    if(is_null($dst)) $dst = fopen('php://temp','c+');
    while(!feof($src)) fwrite($dst,fread($src,1024)?:'');
    return $dst;
}

// Make sure we get the minimum params
if(!isset($params['spec'])) perror('Spec missing from the parameters');
$spec = $params['spec'];

// Ensure the said spec has a src
if(!file_exists('src'.DS.$spec.'.md')) perror('Given source does not exist');
$filename = implode(DS,[__DIR__,'src',$spec.'.md']);

// Fetch the file's headers
$fd       = fopen($filename,'r+');
$headers  = '';
while(!feof($fd)) {
    $line = trim(fgets($fd));
    if(!$line) break;
    $headers .= $line . "\n";
}
$headers = unflatten(configFile($headers));

class Pipe {
    protected $processor = null;
    protected $next      = null;
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
        if(is_resource($this->processor)) return fwrite($this->processor,$chunk);
        if(is_callable($this->processor)) return call_user_func($this->processor,$chunk,$this->next);
        return false;
    }
}
function normalize_newlines( $chunk, Pipe $next ) {
    $next->write(str_replace(["\r\n","\r"],"\n",$chunk));
}
function inclusions( $chunk, Pipe $next ) {
    if(substr($chunk,0,1)=='<') {
        $fd = fopen('src'.DS.substr(trim($chunk),1).'.md','r');
        while(!feof($fd)) $next->write(fgets($fd));
        fclose($fd);
    } else {
        $next->write($chunk);
    }
}

// Build the processing pipe
$outfd = fopen('spec'.DS.'spec'.$spec.'.txt','c+');
ftruncate($outfd,0);
$pipe = new Pipe([
    'normalize_newlines',
    'inclusions',
    $outfd,
]);

// Run data through the pipe
var_dump($pipe);
while(!feof($fd)) $pipe->write(fgets($fd));
var_dump($pipe);

//// Handle file inclusions
//$temp_fd = fopen('php://temp','c+');
//while(!feof($process_fd)) {
//    $line = fgets($process_fd);
//    if(substr($line,0,1)==='<') {
//        $fd = fopen('src'.DS.trim(substr($line, 1)) . '.md', 'r');
//        var_dump('src'.DS.trim(substr($line, 1)) . '.md');
//        fcopy($fd, $temp_fd);
//        fclose($fd);
//    } else {
//        fwrite($temp_fd,$line);
//    }
//}
//
//// Rewind again
//fseek($process_fd,0);
//ftruncate($process_fd,0);
//fseek($temp_fd,0);
//fcopy($temp_fd,$process_fd);
//fseek($process_fd,0);
//fseek($temp_fd,0);
//ftruncate($temp_fd,0);
//
//
//
//
//
//echo stream_get_contents($process_fd);
//
//
////var_dump($config);
////var_dump($contents);
//var_dump($headers);
//var_dump($params);
