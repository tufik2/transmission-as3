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
import java.io.FileOutputStream;
import java.io.IOException;

public class TransmissionStandardStream extends ByteArrayOutputStream
{
	public enum StandardStreamType 
	{
		STANDARD_OUTPUT, STANDARD_ERROR
	};
	
	private String lineSeparator;
	private StandardStreamType streamType;
	private FileOutputStream fileOutputStream;
	
	/**
	 * Initializes a stream and a FileOutputStream to write it to.
	 * 
	 * @param streamType The type of stream (output or error).
	 * @param fileOutputStream The file the output stream will write to.
	 */
	public TransmissionStandardStream(StandardStreamType streamType, FileOutputStream fileOutputStream)
	{
		super();
		
		lineSeparator = System.getProperty("line.separator");
		this.streamType = streamType;
		this.fileOutputStream = fileOutputStream;
	}
	
	public TransmissionStandardStream(StandardStreamType streamType)
	{
		super();
		
		lineSeparator = System.getProperty("line.separator");
		this.streamType = streamType;
		this.fileOutputStream = null;
	}
	
	/**
	 * This method gets called any time the PrintStream is written to. We can intercept the output
	 * and write it to a file for debugging.
	 * 
	 * This will effectively redirect System.out and System.err to a logging file.
	 */
	public void flush() throws IOException
	{
		String record;
		
		synchronized(this)
		{
			super.flush();
			
			record = this.toString();
			
			if (record.length() == 0 || record.equals(lineSeparator))
			{
				// Avoid empty records
				writeToFile(record.getBytes());
				
				super.reset();
				return;
			}
			
			if (streamType == StandardStreamType.STANDARD_OUTPUT)
			{
				record = "OUT: " + record;
			}
			else if (streamType == StandardStreamType.STANDARD_ERROR)
			{
				record = "ERR: " + record;
			}
			
			// If a file output stream is available, write the bytes to it. Otherwise don't.
			if (fileOutputStream != null)
			{
				writeToFile(record.getBytes());
			}
			
			super.reset();
		}
	}
	
	/**
	 * Writes bytes to a file if the .transmissionLog.log files exists.
	 * 
	 * @param bytes the bytes to write to the file.
	 * @throws IOException
	 */
	public void writeToFile(byte[] bytes) throws IOException
	{
		if (fileOutputStream != null)
		{
			fileOutputStream.write(bytes);
		}
	}
}
