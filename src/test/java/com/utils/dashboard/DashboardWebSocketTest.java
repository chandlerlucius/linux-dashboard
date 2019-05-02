package com.utils.dashboard;

import java.io.File;
import org.junit.Test;
import org.junit.Assert;

public class DashboardWebSocketTest {

    public DashboardWebSocketTest() {
        // This constructor is intentionally empty. Nothing special is needed here.
    }

    @Test
    public void copyExecScriptToTempDir_ValidInputOutputPath_FileExistsAndExecutable() {
        final DashboardWebSocket dashboardWebSocket = new DashboardWebSocket(true);
        final String filePath = dashboardWebSocket.copyExecScriptToTempDir("/sh/ServerStats.sh", "ServerStats.sh");
        final File file = new File(filePath);
        Assert.assertTrue("Expected file to have been copied to temp directory.", file.exists());
        Assert.assertTrue("Expected file to be executable.", file.canExecute());
    }

    @Test
    public void copyExecScriptToTempDir_InvalidInputOutputPath_FileDoesNotExist() {
        final DashboardWebSocket dashboardWebSocket = new DashboardWebSocket(true);
        final String filePath = dashboardWebSocket.copyExecScriptToTempDir("/sh/NotValid.sh", "NotValid.sh");
        final File file = new File(filePath);
        Assert.assertFalse("Expected file to not have been copied to temp directory.", file.exists());
    }

}