package com.utils.dashboard;

import java.io.File;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;

/**
 * This class is responsible for unit testing WebSocket.java.
 * 
 * @author Chandler Lucius
 * @version 1.0.0
 * @since 1.0.0
 */
public class WebSocketTest {

    @Test
    public void copyExecScriptToTempDir_ValidInputOutputPath_FileExistsAndExecutable() {
        final WebSocket webSocket = new WebSocket();
        final String filePath =
                webSocket.copyScriptToTempDir("/sh/ServerStats.sh", "ServerStats.sh");
        final File file = new File(filePath);
        Assertions.assertTrue(file.exists(),
                "Expected file to have been copied to temp directory.");
        Assertions.assertTrue(file.canExecute(), "Expected file to be executable.");
    }

    @Test
    public void copyExecScriptToTempDir_InvalidInputOutputPath_FileDoesNotExist() {
        final WebSocket webSocket = new WebSocket();
        final String filePath = webSocket.copyScriptToTempDir("/sh/NotValid.sh", "NotValid.sh");
        final File file = new File(filePath);
        Assertions.assertFalse(file.exists(),
                "Expected file to not have been copied to temp directory.");
    }

}
