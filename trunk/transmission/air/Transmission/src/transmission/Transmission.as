////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Copyright 2010 Nate Ross
// 
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
// 
//      http://www.apache.org/licenses/LICENSE-2.0
// 
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
//  Transmission - AIR 2.0 to Java Communication Layer
//
////////////////////////////////////////////////////////////////////////////////////////////////////

package transmission
{
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.errors.EOFError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.system.Capabilities;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.IDataInput;
	
	import transmission.events.TransmissionErrorEvent;
	
	[Event(name="ioError",type="flash.events.IOErrorEvent")]
	[Event(name="transmissionError",type="transmission.events.TransmissionErrorEvent")]
	[Event(name="exit",type="flash.events.NativeProcessExitEvent")]
	
	/**
	 * A class to manage the native process communication between AIR 2.0 and Java.  This class can
	 * start up a Java process and communicate via standard input/output.
	 */
	public dynamic class Transmission extends EventDispatcher
	{
		protected var nativeProcess:NativeProcess;
		
		protected var initialized:Boolean = false;
		
		protected var lengthByteArray:ByteArray = new ByteArray();
		protected var messageByteArray:ByteArray = new ByteArray();
		protected var expectingMessageData:Boolean = false;
		protected var expectingLengthData:Boolean = true;
		
		protected var messageLength:int = -1;
		
		protected var messageHandlersMap:Dictionary;
		
		public function Transmission(singletonBlocker:Transmission_SingletonBlocker)
		{
			messageHandlersMap = new Dictionary(false);
		}
		
		/**
		 * Should be called before any messages are sent/received. A config.xml file path should be
		 * supplied which configures the location of the java executable, the location of 
		 * Transmission.jar, relative classpaths, and the package/classname of the 
		 * TransmissionController subclass which will define the message handlers on the Java side.
		 * 
		 * @param executablePath The path to the Java executable (or Java Application Bundle on Mac)
		 * @param transmissionControllerPackage The java classpath to the transmission controller
		 * @param classpaths An array of String paths for all java jar dependencies (can be 
		 * individual jars or directories that contain jars).
		 * @param if true, remote debugging is enabled. False otherwise.
		 */
		public function init(executablePath:String, transmissionControllerPackage:String = "", 
				classpaths:Array = null, debug:Boolean = true):void
		{
			if (!initialized)
			{
				startupJavaProcess(executablePath, transmissionControllerPackage, classpaths, debug);
				initialized = true;
			}
		}
		
		/**
		 * Closes the native process.
		 * 
		 * @param force Forces the native process to close.
		 */
		public function exit(force:Boolean = false):void
		{
			if (nativeProcess)
			{
				nativeProcess.exit(force);
			}
		}
		
		/**
		 * Registers a message handler to transmission. The message handler will be notified when a
		 * message of the same type is received from standard output.
		 */
		public function addMessageHandler(messageType:String, mh:IMessageHandler):void
		{
			var messageHandlers:Array = messageHandlersMap[messageType];
			
			if (!messageHandlers)
			{
				messageHandlers = new Array();
				messageHandlersMap[messageType] = messageHandlers;
			}
			
			messageHandlers.push(mh);
		}
		
		/**
		 * Unregisters a message handler from transmission. This message handler will no longer be
		 * notified when a message of the same type is received from standard output.
		 */
		public function removeMessageHandler(messageType:String, mh:IMessageHandler):void
		{
			var messageHandlers:Array = messageHandlersMap[messageType];
			
			if (messageHandlers)
			{
				if (messageHandlers.length > 1)
				{
					messageHandlers.splice(messageHandlers.indexOf(mh), 1);
				}
				else
				{
					delete messageHandlersMap[messageType];
				}
			}
		}
		
		/**
		 * Writes a message to standard input for Java to consume.
		 */
		public function sendMessage(m:Message):void
		{
			if (!initialized)
			{
				throw new Error("Call the init method and wait until the INITIALIZED " +
					"TransmissionEvent is dispatched");
			}
			
			nativeProcess.standardInput.writeObject(m);
		}
		
		/**
		 * Starts up the java process
		 */
		protected function startupJavaProcess(executablePath:String, 
				transmissionControllerPackage:String, classpaths:Array, debug:Boolean):void
		{
			var info:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			info.workingDirectory = File.applicationDirectory;
			info.executable = File.applicationDirectory.resolvePath(executablePath);
			
			var args:Vector.<String> = new Vector.<String>();
			
			// Debug must be turned on and there must be a transmissionControllerPackage specified.
			// If the executable is a java-wrapper that already contains the arguments and classpath
			// information like Jar Bundler on Mac OSX does, don't add this argument because it will
			// break.
			if (debug && transmissionControllerPackage)
			{
				args.push("-Xdebug");
				args.push("-Xrunjdwp:transport=dt_socket,address=8000,server=y,suspend=n");
			}
			
			// Add the classpath argument
			if (classpaths && classpaths.length)
			{
				var jarPaths:Array = new Array();
				
				// Look for directories that may contain jars
				for (var i:int = 0; i < classpaths.length; i++)
				{
					var file:File = File.applicationDirectory.resolvePath(classpaths[i]);
					
					if (file.isDirectory)
					{
						var childFiles:Array = file.getDirectoryListing();
						for each (var childFile:File in childFiles)
						{
							if (!childFile.isDirectory && childFile.extension.toLowerCase() == "jar")
							{
								jarPaths.push(childFile.getRelativePath(info.workingDirectory));
							}
						}
					}
					else
					{
						jarPaths.push(file.getRelativePath(info.workingDirectory));
					}
				}
				
				args.push("-cp");
				args.push(jarPaths.join(classpathSeparator));
			}
			
			// Add the transmissionControllerPackage argument.
			if (transmissionControllerPackage && transmissionControllerPackage.length)
			{
				args.push("transmission.Transmission");
				args.push("-transmissionControllerPackage", transmissionControllerPackage);
			}
			
			info.arguments = args;
			
			nativeProcess = new NativeProcess();
			nativeProcess.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onOutputData);
			nativeProcess.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, onErrorData);
			nativeProcess.addEventListener(IOErrorEvent.STANDARD_OUTPUT_IO_ERROR, onStandardOutputIoError);
			nativeProcess.addEventListener(IOErrorEvent.STANDARD_INPUT_IO_ERROR, onStandardInputIoError);
			nativeProcess.addEventListener(Event.STANDARD_OUTPUT_CLOSE, onStandardOutputClose);
			nativeProcess.addEventListener(Event.STANDARD_INPUT_CLOSE, onStandardInputClose);
			nativeProcess.addEventListener(NativeProcessExitEvent.EXIT, onExit);
			nativeProcess.start(info);
			
			// Reset length and message data
			lengthByteArray = new ByteArray();
			messageByteArray = new ByteArray();
			expectingMessageData = false;
			expectingLengthData = true;
		}
		
		/**
		 * @private
		 * The method is responsible for taking output or error data from the standard stream and
		 * piecing it together across multiple frames.
		 */
		protected function parseStandardData(dataInput:IDataInput, event:ProgressEvent):void
		{
			// Take a snapshot of the bytesAvailable from the input source (either standard output
			// or standard error). One odd behavior of AIR is that if lots of large messages are
			// received, the dataInput's bytesAvailable property will be filled immediately after
			// it is read from. This behavior makes the dataInput's bytesAvailable somewhat of a
			// magic number.  We only want to consume as many bytes that are available at this
			// point.
			var bytesAvailable:int = dataInput.bytesAvailable;
			
			// Watch for EOFErrors. These will occur if AIR misleads us into thinking their are
			// more bytesAvailable than there actually are. This behavior seems to happens when lots
			// and lots of bytes are being sent at the same time.
			try
			{
				// If we still have bytes available to read, continue reading them until the buffer
				// is exhausted.
				while (bytesAvailable > 0)
				{
					var baLength:int;
					
					// We are currently expecting the message's length of 4 bytes to be read. This
					// will tell us how large the actual message is so we can piece it together 
					// across multiple frames if necessary.
					if (expectingLengthData)
					{
						// Take either 4 bytes, if it is available, or the remainder of the buffer
						// if there are fewer than 4 bytes.
						baLength = Math.min(4 - lengthByteArray.length, bytesAvailable);
						dataInput.readBytes(lengthByteArray, lengthByteArray.length, baLength);
						bytesAvailable -= baLength;
						
						// We received all 4 bytes during this frame.
						if (lengthByteArray.length == 4)
						{
							messageLength = lengthByteArray.readInt();
							lengthByteArray.clear();
							
							// If the messageLength is some rediculously high number, it probably
							// doesn't have a message length header attached to it, and we are 
							// actually pulling 4 bytes from the message itself. If this is the case
							// it is probably a System.out.print trace statement that was never
							// removed. Print that to the console and then wait for the next 
							// message.
							if (messageLength > 10000000)
							{
								var temp:ByteArray = new ByteArray();
								temp.writeInt(messageLength);
								dataInput.readBytes(temp, 4, event.bytesLoaded - 4);
								
								temp.position = 0;
								var print:* = temp.readMultiByte(temp.length, "iso-8859-1");
								temp.clear();
								
								trace(print);
								return;
							}
							
							// We have received all of our message length information, time to read
							// the message itself.
							expectingLengthData = false;
							expectingMessageData = true;
						}
						// We only received 1, 2, or 3 bytes during this frame and need to wait until 
						// the next progress event to receive the rest.
						else 
						{
							expectingLengthData = true;
							expectingMessageData = false;
						}
					}
					
					// We have received the appropriate length data, now time to read the message 
					// itself.
					if (expectingMessageData)
					{
						// Read either the remaining amount of bytes for this message, or the number
						// of remaining bytes from the buffer... whichever is smallest.
						baLength = Math.min(messageLength - messageByteArray.length, bytesAvailable);
						dataInput.readBytes(messageByteArray, messageByteArray.length, baLength);
						bytesAvailable -= baLength;
						
						// We received the entire message, let's serialize the AMF data and 
						// broadcast the message to all listeners.
						if (messageByteArray.length == messageLength)
						{
							// Get ready to read the 4 length bytes of the next message.
							expectingLengthData = true;
							expectingMessageData = false;
							
							var obj:Object = messageByteArray.readObject();
							
							// At this point, the object should only be either a Message or a
							// TransmissionError object.
							if (obj is Message)
							{
								dispatchMessage(Message(obj));
							}
							else if (obj is TransmissionError)
							{
								dispatchError(TransmissionError(obj));
							}
							messageByteArray.clear();
						}
						// We only received a partial transmission of message bytes. The 
						// messageLength variable says we still have more, so let's wait until the 
						// next progress event so we can receive the rest.
						else
						{
							expectingLengthData = false;
							expectingMessageData = true;
						}
					}
				}
			}
			catch (e:EOFError)
			{
				// We reached the end of the file. AIR mislead us into thinking there were more
				// bytes available in the buffer than there actually was. This usually only happens
				// on the very last frame of an extremely large burst of transmissions.
			}
		}
		
		/**
		 * The classpath separator in Windows is different from Unix-based java.
		 */
		protected function get classpathSeparator():String
		{
			return (Capabilities.os.toLowerCase().indexOf("win") > -1) ? ";" : ":";
		}
		
		/**
		 * @private
		 * Dispatches a message object received from Java to all message handlers that have been
		 * registered.
		 */
		protected function dispatchMessage(m:Message):void
		{
			if (m)
			{
				var messageHandlers:Array = messageHandlersMap[m.type];
				
				if (messageHandlers)
				{
					for each (var mh:IMessageHandler in messageHandlers) 
					{
						mh.handleMessage(m);
					}
				}
			}
			else
			{
				throw new Error("Error! The message received is null!");
			}
		}
		
		/**
		 * @private
		 * Dispatches a transmissionError object received from Java to Transmission's error handler.
		 */
		protected function dispatchError(te:TransmissionError):void
		{
			if (te)
			{
				dispatchEvent(new TransmissionErrorEvent(TransmissionErrorEvent.TRANSMISSION_ERROR, te));
			}
		}
		
		/**
		 * @private
		 * Dispatched when the native process has exited.
		 */
		private function onExit(event:NativeProcessExitEvent):void
		{
			dispatchEvent(event);
		}
		
		/**
		 * @private
		 * Called when standard output closes.
		 */
		private function onStandardOutputClose(event:Event):void
		{
			trace(event);
		}
		
		/**
		 * @private
		 * Called when standard input closes.
		 */
		private function onStandardInputClose(event:Event):void
		{
			trace(event);
		}
		
		/**
		 * @private
		 * Called when an IO error occurs on standard input.
		 */
		private function onStandardInputIoError(event:IOErrorEvent):void
		{
			trace(event);
			throw new Error(event.toString());
		}
		
		/**
		 * @private
		 * Called when an IO error occurs on standard output.
		 */
		private function onStandardOutputIoError(event:IOErrorEvent):void
		{
			trace(event);
			throw new Error(event.toString());
		}
		
		/**
		 * @private
		 * Called when output is received via standard out. The byte stream consists of 4 bytes
		 * which tell how long the message will be, followed by the message object itself.
		 * 
		 * Sometimes message bytes are not completely sent during each frame. When these partial
		 * transmissions occurs, we need to wait until the next ProgressEvent.STANDARD_OUTPUT_DATA
		 * event and then append what we have to the beginning of the next transmission.
		 */
		protected function onOutputData(event:ProgressEvent):void
		{
			parseStandardData(nativeProcess.standardOutput, event);
		}
		
		
		
		/**
		 * @private
		 * Called when output is received via standard error. The byte stream consists of 4 bytes
		 * which tell how long the message will be, followed by the message object itself.
		 * 
		 * Sometimes message bytes are not completely sent during each frame. When these partial
		 * transmissions occurs, we need to wait until the next ProgressEvent.STANDARD_ERROR_DATA
		 * event and then append what we have to the beginning of the next transmission.
		 */
		protected function onErrorData(event:ProgressEvent):void
		{
			parseStandardData(nativeProcess.standardError, event);
		}
		
		//----------------------------------------------------------------------------//
		// Singleton Implementation
		
		private static var _instance:Transmission = null;
		
		/**
		 *  The singleton instance of <code>Transmission</code>.
		 */
		public static function getInstance():Transmission
		{
			if ( _instance == null )
			{
				_instance = new Transmission(new Transmission_SingletonBlocker);
			}
			return _instance;
		}
	}
}

/**
 *  The <code>Transmission_SingletonBlocker</code> class is a private inner class
 *  used to block the instantiation of <code>Transmission</code> from outside of
 *  the <code>Transmission</code> class.
 */
class Transmission_SingletonBlocker {}