package transmission.demo;

import transmission.ITransmissionController;
import transmission.Transmission;

public class TransmissionDemoController implements ITransmissionController
{
	
	public void initializeMessageHandlers()
	{
		Transmission.getInstance().addMessageHandler("test", new DemoMessageHandler());
	}

}
