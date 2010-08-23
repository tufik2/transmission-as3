package transmission.demo;

import transmission.IMessageHandler;
import transmission.Message;

public class DemoMessageHandler implements IMessageHandler
{
	
	public void handleMessage(Message message)
	{
		DemoObject obj = (DemoObject)message.getData();
		new Message("test", new DemoObject(obj.getId(), obj.getText() + " || sent back!")).send();
	}

}
