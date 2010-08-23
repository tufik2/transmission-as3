package transmission.demo;

public class DemoObject
{
	private int id;
	private String text;
	
	public DemoObject()
	{
		
	}
	
	public DemoObject(int id, String text)
	{
		this.id = id;
		this.text = text;
	}
	
	public void setId(int id)
	{
		this.id = id;
	}
	public int getId()
	{
		return id;
	}
	
	public void setText(String text)
	{
		this.text = text;
	}
	public String getText()
	{
		return text;
	}
}
