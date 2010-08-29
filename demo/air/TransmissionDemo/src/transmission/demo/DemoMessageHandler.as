//
//  Created on Aug 22, 2010.
//  Copyright 2010 Rain. All rights reserved.
//

package transmission.demo
{
	import transmission.IMessageHandler;
	import transmission.Message;
	
	public class DemoMessageHandler implements IMessageHandler
	{
		public function DemoMessageHandler()
		{
		}
		
		public function handleMessage(message:Message):void
		{
			var obj:DemoObject = message.data as DemoObject;
			Model.getInstance().demoObject = obj;
		}
	}
}