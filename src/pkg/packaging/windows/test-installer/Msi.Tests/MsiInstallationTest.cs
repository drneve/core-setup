// Copyright (c) .NET Foundation and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.

using System;
using System.IO;
using Xunit;

namespace Msi.Tests
{
    public class MsiInstallationTest
    {

       /*
        public static void InstallTest(MsiManager _msiMgr, ExeManager _exeMgr)
        {
	    if(_msiMgr.IsInstalled){
		Console.WriteLine("Uninstalling");
		_exeMgr.UnInstall();
           	Assert.False(_msiMgr.IsInstalled);
	    }
	    else{
    		Console.WriteLine("Installing");
		 _exeMgr.Install();
                 Assert.True(_msiMgr.IsInstalled);
	    }
	}
	*/
        public static void InstallTest(MsiManager _msiMgr, ExeManager _exeMgr)
        {
            // make sure that the msi is not already installed, if so the machine is in a bad state
            Assert.False(_msiMgr.IsInstalled, "The dotnet CLI msi is already installed");

            _exeMgr.Install();
            Assert.True(_msiMgr.IsInstalled);

            _exeMgr.UnInstall();
            Assert.False(_msiMgr.IsInstalled);
        }
   }
}
