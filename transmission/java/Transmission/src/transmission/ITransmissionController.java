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
 * The interface that a Transmission-powered application should implement. The 
 * TransmissionController registers all message handlers with Transmission.
 */
public interface ITransmissionController
{
	/**
	 * This method should be extended to register all expected messages with Transmission.
	 */
	public void initializeMessageHandlers();
}
