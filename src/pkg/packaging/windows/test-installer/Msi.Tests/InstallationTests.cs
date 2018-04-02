// Copyright (c) .NET Foundation and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.

using System;
using System.IO;
using System.Collections.Generic;
using Xunit;

[assembly: CollectionBehavior(DisableTestParallelization = true)]

namespace Msi.Tests
{
    public class InstallationTests 
    {
        //public static List<MsiManager> _listMsiMgr;
        private ExeManager _exeMgr;

        public InstallationTests()
        {
            var exeFile = Environment.GetEnvironmentVariable("RUNTIME_EXE");
	    Console.WriteLine(exeFile);
	    _exeMgr = new ExeManager(exeFile);

	   /* _listMsiMgr = new List<MsiManager>();
            var msiList = Environment.GetEnvironmentVariable("MSI_LIST");
	    Console.WriteLine(msiList);
	    string[] lines = System.IO.File.ReadAllLines(msiList);
	    foreach( string msi in lines )
	    {
		     MsiManager _msiMgr = new MsiManager(msi);
		     _listMsiMgr.Add(_msiMgr);
	    }*/

        } 


	public static IEnumerable<object[]> ListMsiMgr(){
		var msiList = Environment.GetEnvironmentVariable("MSI_LIST");
		Console.WriteLine("HEEEERE" + msiList);
		string[] lines = System.IO.File.ReadAllLines(msiList);
		foreach( string msi in lines){
		    yield return new object[] { new MsiManager(msi) }; 
		}
	}

	[Theory]
	[MemberData(nameof(ListMsiMgr))]
	public void Bla(MsiManager msiMgr){
		MsiInstallationTest.InstallTest(msiMgr, _exeMgr);
	}

/*	[Fact] 
	public void InstallationTest()
	{
		foreach( var msiMgr in _listMsiMgr)
		{
			MsiInstallationTest.InstallTest(msiMgr, _exeMgr);
		}
	}*/
   }
}
