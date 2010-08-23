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
	import mx.collections.ArrayCollection;
	
	[Bindable]
	[RemoteClass(alias="transmission.TransmissionError")]
	
	/**
	 * A message type received from Java whenever an error occurs.
	 */
	public class TransmissionError
	{
		/**
		 * Reason for the error.
		 */
		public var message:String;
		
		/**
		 * Details about the error.
		 */
		public var detail:String;
		
		/**
		 * A stack trace from Java for debugging purposes.
		 */
		public var stackList:ArrayCollection;
		
		public function TransmissionError()
		{
		}
	}
}