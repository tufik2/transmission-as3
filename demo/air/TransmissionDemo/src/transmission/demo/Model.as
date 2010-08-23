//
//  Created on Aug 22, 2010.
//  Copyright 2010 Rain. All rights reserved.
//

package transmission.demo
{
	[Bindable]
	public class Model
	{
		public var label:String;
		
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