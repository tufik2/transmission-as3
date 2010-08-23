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

package transmission;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.PrintStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import transmission.TransmissionStandardStream.StandardStreamType;


import flex.messaging.io.SerializationContext;
import flex.messaging.io.amf.Amf3Output;

/**
 * A class to manage the native process communication between AIR 2.0 and Java.
 */
public class Transmission
{
	protected TransmissionListenerThread listenerThread;
	protected Map<String, List<IMessageHandler>> messageHandlerMap;
	
	ByteArrayOutputStream _byteArrayOutputStream = new ByteArrayOutputStream();
	Amf3Output _amf3Output = new Amf3Output(new SerializationContext());
	
	PrintStream realSystemOut;
	PrintStream realSystemErr;
	
	PrintStream debugSystemOut;
	PrintStream debugSystemErr;
	
	public Transmission()
	{
		initializePrintStreams();
		
		messageHandlerMap = new HashMap<String, List<IMessageHandler>>();
		
		listenerThread = new TransmissionListenerThread();
		listenerThread.start();
	}
	
	/**
	 * Set up print stream configuration for stdout and stderr. We will redirect standard output and
	 * error to a file for every message that does not go through Transmission.
	 */
	private void initializePrintStreams()
	{
		realSystemOut = System.out;
		realSystemErr = System.err;
		
		// Look to see if a debugging file ".transmissionLog.log" exists in the user's home 
		// directory. If it does, use it for debugging.
		FileOutputStream fos = null;
		try
		{
			File debugFile = new File(System.getProperty("user.home") + "/.transmissionLog.log");
			
			if (debugFile.exists())
			{
				// Clear the original contents of the file.
				FileOutputStream eraser = new FileOutputStream(debugFile);
				eraser.write(new String().getBytes());
				eraser.close();
				
				fos = new FileOutputStream(debugFile);
			}
		}
		catch (Exception e)
		{
			// If the file doesn't exist, don't worry about it, it's only for debugging purposes.
		}
		
		// Create a standard output and error stream that we'll use to send all non-transmission 
		// messages to the debug file ".transmissionLog.log" so they don't go to AIR 2.0.
		TransmissionStandardStream out = new TransmissionStandardStream(StandardStreamType.STANDARD_OUTPUT, fos);
		TransmissionStandardStream err = new TransmissionStandardStream(StandardStreamType.STANDARD_ERROR, fos);
		debugSystemOut = new PrintStream(out, true);
		debugSystemErr = new PrintStream(err, true);
		
		System.setOut(debugSystemOut);
		System.setErr(debugSystemErr);
	}

	/**
	 * Calls the <code>initializeMessageHandlers</code> method on the subclassed
	 * <code>TransmissionController</code> contained in the Transmission-powered application.
	 * 
	 * @param controller
	 */
	public void init(ITransmissionController controller)
	{
		controller.initializeMessageHandlers();
	}
	
	/**
	 * Sends a message over standard output back to AIR. Before each message goes out, 4 bytes are
	 * sent which let AIR know how large of a message to expect (in bytes).
	 * 
	 * @param message The message object to send.
	 */
	public synchronized void sendMessage(Message message)
	{
		try
		{
			// Switch to actual system.out for sending transmission messages.
			System.setOut(realSystemOut);
			
			_byteArrayOutputStream.reset();
			
			_amf3Output.reset();
			_amf3Output.setOutputStream(_byteArrayOutputStream);
			_amf3Output.writeObject(message);
			
			byte[] byteArray = _byteArrayOutputStream.toByteArray();
			writeMessageToStream(System.out, byteArray);
			
			// Switch back to our debugging system.out which writes all output to a file.
			System.setOut(debugSystemOut);
		}
		catch (IOException e)
		{
			new TransmissionError("Error sending message", e).send();
		}
	}
	
	/**
	 * Sends a TransmissionError over standard error back to AIR.
	 * 
	 * @param te
	 */
	public synchronized void sendError(TransmissionError te)
	{
		try
		{
			// Switch to actual system.err for sending transmission messages.
			System.setErr(realSystemErr);
			
			_byteArrayOutputStream.reset();
			
			_amf3Output.reset();
			_amf3Output.setOutputStream(_byteArrayOutputStream);
			_amf3Output.writeObject(te);
			
			byte[] byteArray = _byteArrayOutputStream.toByteArray();
			writeMessageToStream(System.err, byteArray);
			
			// Switch back to our debugging system.err which writes all output to a file.
			System.setErr(debugSystemErr);
		}
		catch (IOException e)
		{
			// If we fail sending an error, do nothing...
		}
	}
	
	/**
	 * Writes a Message to standard output or a TransmissionError to standard error.  Before either
	 * message type is sent, 4 length bytes are sent out to let AIR 2.0's Transmission instance know
	 * how large of a message to expect.
	 * 
	 * @param ps The print stream we are writing to.
	 * @param byteArray The serialized AMF object we will send
	 */
	protected synchronized void writeMessageToStream(PrintStream ps, byte[] byteArray) throws IOException
	{
		// Write the length of the message so AIR knows how large of a message to expect.
		ps.write(byteArray.length >> 24 & 0xFF);
		ps.write(byteArray.length >> 16 & 0xFF);
		ps.write(byteArray.length >> 8 & 0xFF);
		ps.write(byteArray.length & 0xFF);
		
		// Write the actual message
		ps.write(byteArray);
		ps.flush();
	}
	
	/**
	 * Dispatches a message that has been received from AIR to all Java handlers that have 
	 * registered for that particular message type.
	 * 
	 * @param m
	 */
	public void dispatchMessage(Message m)
	{
		List<IMessageHandler> list = messageHandlerMap.get(m.getType());
		
		if (list != null)
		{
			for (IMessageHandler messageHandler : list)
			{
				messageHandler.handleMessage(m);
			}
		}
	}
	
	/**
	 * Registers a MessageHandler with Transmission so it will be notified via it's
	 * <code>handleMessage</code> method when AIR sends a message of that particular
	 * <code>messageType</code>
	 * 
	 * @param messageType
	 * @param mh
	 */
	public void addMessageHandler(String messageType, IMessageHandler mh)
	{
		List<IMessageHandler> list = messageHandlerMap.get(messageType);
		
		if (list == null)
		{
			list = new ArrayList<IMessageHandler>();
			messageHandlerMap.put(messageType, list);
		}
		
		list.add(mh);
	}
	
	/**
	 * De-registers a MessageHandler with Transmission so it will no longer be notified when AIR
	 * sends a message of that particular <code>messageType</code>
	 * 
	 * @param messageType
	 * @param mh
	 */
	public void removeMessageHandler(String messageType, IMessageHandler mh)
	{
		List<IMessageHandler> list = messageHandlerMap.get(messageType);
		
		if (list != null)
		{
			if (list.size() > 1)
			{
				list.remove(mh);
			}
			else
			{
				messageHandlerMap.remove(messageType);
			}
		}
	}

	/**
	 * Called by AIR's native process when the Java application is started. This main method should
	 * be called with args <code>transmissionControllerPackage</code> which points to the 
	 * package/classname of the subclassed <code>TransmissionController</code> in the 
	 * Transmission-powered application which registers all applicable message handlers with 
	 * Transmission.
	 * 
	 * @param args
	 */
	public static void main(String[] args)
	{
		String transmissionControllerPackage = null;
		
		// Get the transmissionControllerPackage from the arguments that have been supplied from
		// AIR 2.0.
		for (int i = 0; i < args.length; i++)
		{
			if (args[i].equals("-transmissionControllerPackage") && args.length > i + 1)
			{
				transmissionControllerPackage = args[i + 1];
			}
		}
		
		if (transmissionControllerPackage != null)
		{
			try
			{
				// Instantiate the subclassed TransmissionController.
				ITransmissionController controller = (ITransmissionController)Class.forName(transmissionControllerPackage).newInstance();
				Transmission.getInstance().init(controller);
			}
			catch (Exception e)
			{
				new TransmissionError("A TransmissionController could not be located. Check your " +
						"classpaths and try again.", e).send();
			}
		}
	}
	

	
	//--------------------------------------------------------------------------------------------//
	// Singleton pattern
	
	private static Transmission instance = new Transmission();
	
	public static Transmission getInstance()
	{
		return instance;
	}

}
