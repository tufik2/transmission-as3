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

/**
 * A message object that is passed between AIR 2.0 and Java. Each instance of this object serves
 * as a communication between the two platforms.
 */
public class Message
{
	private String type;
	private Object data;
	
	public Message(String type, Object data)
	{
		this.type = type;
		this.data = data;
	}
	
	public Message(String type)
	{
		this.type = type;
	}
	
	public Message()
	{
		
	}
	
	/**
	 * A convenience method for sending this message to Java.
	 */
	public void send()
	{
		Transmission.getInstance().sendMessage(this);
	}
	
	/**
	 * The type of message. This property is used to forward the message to its appropriate
	 * transmission handler and functions much like the type property on an event. 
	 */
	public String getType()
	{
		return type;
	}
	public void setType(String type)
	{
		this.type = type;
	}
	
	/**
	 * The data payload.
	 */
	public Object getData()
	{
		return data;
	}
	public void setData(Object data)
	{
		this.data = data;
	}
}
