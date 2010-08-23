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

package transmission.events
{
	import transmission.TransmissionError;
	
	import flash.events.Event;
	
	/**
	 * This event is used to package any TransmissionError object that comes across standard output.
	 */
	public class TransmissionErrorEvent extends Event
	{
		public static const TRANSMISSION_ERROR:String = "transmissionError";
		
		private var _transmissionError:TransmissionError;
		
		public function TransmissionErrorEvent(type:String, transmissionError:TransmissionError, 
				bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			
			_transmissionError = transmissionError;
		}
		
		/**
		 * The transmissionError object dispatched from Java.
		 */
		public function get transmissionError():TransmissionError
		{
			return _transmissionError;
		}
		
		/**
		 * @private
		 */
		 override public function clone():Event
		 {
		 	return new TransmissionErrorEvent(type, transmissionError, bubbles, cancelable);
		 }
		 
		 /**
		  * @private
		  */
		 override public function toString():String
		 {
		 	return formatToString('TransmissionErrorEvent', 'type', 'transmissionError', 'bubbles', 
					'cancelable');
		 }
	}
}