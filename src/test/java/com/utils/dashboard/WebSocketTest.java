package com.utils.dashboard;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import java.io.File;
import org.junit.jupiter.api.Test;

/**
 * This class is responsible for unit testing WebSocket.java.
 * 
 * @author Chandler Lucius
 * @version 1.0.0
 * @since 1.0.0
 */
public class WebSocketTest {

    /**
     * Copy valid script file from webapp to temp directory and verify it
     * exists.
     * 
     * @result Script should be accessible in temp directory and executable.
     */
    @Test
    public void copyExecScriptToTempDir_ValidInputOutputPath_FileExists() {
        final WebSocket webSocket = new WebSocket();
        final String filePath =
                webSocket.copyScriptToTempDir("/sh/ServerStats.sh", "ServerStats.sh");
        final File file = new File(filePath);
        assertTrue(file.exists(),
                "Expected file to have been copied to temp directory.");
    }

    /**
     * Copy valid script file from webapp to temp directory, verify it 
     * exists, and make it executable.
     * 
     * @result Script should be accessible in temp directory and executable.
     */
    @Test
    public void copyExecScriptToTempDir_ValidInputOutputPath_FileExecutable() {
        final WebSocket webSocket = new WebSocket();
        final String filePath =
                webSocket.copyScriptToTempDir("/sh/ServerStats.sh", "ServerStats.sh");
        final File file = new File(filePath);
        assertTrue(file.canExecute(), "Expected file to be executable.");
    }

    /**
     * Copy non-existing script file from webapp to temp directory.
     * 
     * @result Method should throw errow and not exist.
     */
    @Test
    public void copyExecScriptToTempDir_InvalidInputOutputPath_FileDoesNotExist() {
        final WebSocket webSocket = new WebSocket();
        final String filePath = webSocket.copyScriptToTempDir("/sh/NotValid.sh", "NotValid.sh");
        final File file = new File(filePath);
        assertFalse(file.exists(),
                "Expected file to not have been copied to temp directory.");
    }

}
