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
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	import flash.utils.IExternalizable;
	
	[Bindable]
	[RemoteClass(alias="transmission.Message")]
	
	/**
	 * A message object that is passed between AIR 2.0 and Java. Each instance of this object serves
	 * as a communication between the two platforms.
	 * 
	 * I made this class implement IExternalizable because occasionally nested objects are 
	 * serialized incorrectly without explicitly stating the serialization order in this class. I
	 * believe this is a bug in AMF.
	 */
	public class Message implements IExternalizable
	{
		/**
		 * The type of message. This property is used to forward the message to its appropriate
		 * transmission handler and functions much like the type property on an event. 
		 */
		public var type:String;
		
		/**
		 * The data payload.
		 */
		public var data:Object;
		
		public function Message(type:String = null, data:* = null)
		{
			this.type = type;
			this.data = data;
		}
		
		/**
		 * A convenience method for sending this message to Java. This will only work if 
		 * Transmission has been initialized.
		 */
		public function send():void
		{
			Transmission.getInstance().sendMessage(this);
		}
		
		/**
		 * Make sure the properties are serialized in the correct order.
		 */
		public function readExternal(input:IDataInput):void
		{
			type = input.readObject() as String;
			data = input.readObject();
		}
		
		/**
		 * Make sure the properties are deserialized in the correct order.
		 */
		public function writeExternal(output:IDataOutput):void
		{
			output.writeObject(type);
			output.writeObject(data);
		}
	}
}