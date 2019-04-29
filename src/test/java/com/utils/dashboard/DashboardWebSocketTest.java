package com.utils.dashboard;

import java.io.File;
import org.junit.Test;
import org.junit.Assert;

public class DashboardWebSocketTest {

    @Test
    public void copyExecScriptToTempDir_ValidInputOutputPath_FileExistsAndExecutable() {
        DashboardWebSocket dashboardWebSocket = new DashboardWebSocket(true);
        File tempFile = dashboardWebSocket.copyExecScriptToTempDir("/sh/ServerStats.sh", "ServerStats.sh");
        Assert.assertTrue("Expected file to have been copied to temp directory.", tempFile.exists());
        Assert.assertTrue("Expected file to be executable.", tempFile.canExecute());
    }

    @Test
    public void copyExecScriptToTempDir_InvalidInputOutputPath_FileDoesNotExist() {
        DashboardWebSocket dashboardWebSocket = new DashboardWebSocket(true);
        File tempFile = dashboardWebSocket.copyExecScriptToTempDir("/sh/NotValid.sh", "NotValid.sh");
        Assert.assertFalse("Expected file to not have been copied to temp directory.", tempFile.exists());
    }

}