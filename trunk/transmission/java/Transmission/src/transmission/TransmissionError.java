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

import java.util.ArrayList;
import java.util.List;

/**
 * A message sent to AIR whenever an error exists.
 */
public class TransmissionError
{
	private String message;
	private String detail;
	private List<String> stackList;
	
	public TransmissionError(String message)
	{
		this.message = message;
		this.detail = null;
		this.stackList = null;
	}
	
	public TransmissionError(String message, String detail)
	{
		this.message = message;
		this.detail = detail;
		this.stackList = null;
	}
	
	/**
	 * Uses the stacktrace and the message detail from an exception to create a TransmissionError.
	 * 
	 * @param message A custom message for this error.
	 * @param e An exception.
	 */
	public TransmissionError(String message, Exception e)
	{
		this.message = message;
		this.setDetail(e.getMessage());
		stackList = new ArrayList<String>();
		
		for (StackTraceElement ste : e.getStackTrace())
		{
			stackList.add(ste.toString());
		}
	}
	
	public TransmissionError()
	{
		
	}
	
	/**
	 * A convenience method for sending this message to AIR.
	 */
	public void send()
	{
		Transmission.getInstance().sendError(this);
	}
	
	/**
	 * Reason for the error.
	 */
	public void setMessage(String message)
	{
		this.message = message;
	}

	public String getMessage()
	{
		return message;
	}
	
	/**
	 * Details about the error.
	 */
	public void setDetail(String detail)
	{
		this.detail = detail;
	}

	public String getDetail()
	{
		return detail;
	}
	
	/**
	 * A stack trace for debugging purposes.
	 */
	public void setStackList(List<String> stackList)
	{
		this.stackList = stackList;
	}

	public List<String> getStackList()
	{
		return stackList;
	}
}
