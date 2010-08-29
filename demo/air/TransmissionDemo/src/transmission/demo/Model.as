//
//  Created on Aug 22, 2010.
//  Copyright 2010 Rain. All rights reserved.
//

package transmission.demo
{
	[Bindable]
	public class Model
	{
		//----------------------------------------------------------------------------//
		// demoObject:DemoObject
		
		protected var _demoObject:DemoObject;
		
		public function get demoObject():DemoObject
		{
			return _demoObject;
		}
		
		public function set demoObject(value:DemoObject):void
		{
			if (_demoObject != value)
			{
				_demoObject = value;
				dispatchEvent(new Event("demoObjectPropertyChanged"));
			}
		}

		[Bindable("demoObjectPropertyChanged")]
		public function get label():String
		{
			return "ID: " + demoObject.id + ", Text: " + demoObject.text;
		}
		
		//----------------------------------------------------------------------------------------//
		// Singleton pattern
		
		private static var _instance:Model = null;
		
		public static function getInstance():Model
		{
			if (_instance == null)
			{
				_instance = new Model();
			}
			return _instance;
		}
	}
}