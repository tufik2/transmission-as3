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

import java.io.EOFException;

import flex.messaging.io.SerializationContext;
import flex.messaging.io.amf.Amf3Input;

public class TransmissionListenerThread extends Thread
{
	protected Object sourceObj = null;
	protected Class<?> messageHandlerClass = null;

	public TransmissionListenerThread()
	{

	}

	/**
	 * Performs a while loop checking for new Transmission messages being sent over standard input.
	 */
	public void run()
	{
		Amf3Input amfInput = new Amf3Input(SerializationContext.getSerializationContext());
		amfInput.setInputStream(System.in);

		Object obj;
		amfInput.reset();

		while (true)
		{
			try
			{
				obj = amfInput.readObject();

				if (obj instanceof Message)
				{
					Message message = (Message) obj;
					Transmission.getInstance().dispatchMessage(message);

					amfInput.reset();
				}
			}
			catch (EOFException e)
			{
				// Continue reading.
			}
			catch (Exception e)
			{
				new TransmissionError("The transmitted object is not of type transmission.Message",
						e).send();
			}
		}
	}
}
