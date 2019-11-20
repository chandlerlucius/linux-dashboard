package com.utils.dashboard;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.StandardCopyOption;

import javax.websocket.OnClose;
import javax.websocket.OnError;
import javax.websocket.OnMessage;
import javax.websocket.OnOpen;
import javax.websocket.Session;
import javax.websocket.server.ServerEndpoint;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * This class is responsible for handling the messaging system between the clients and server using
 * Java Websocket API.
 * 
 * @author Chandler Lucius
 * @version 1.0.0
 * @since 1.0.0
 */
@ServerEndpoint("/websocket")
public class WebSocket {

    private static final Logger LOG = LoggerFactory.getLogger(WebSocket.class);
    private static final String SEP = File.separator;
    private static final String RUN_SCRIPT = "gimme";

    static {
        copyScriptToTempDir("/sh/ServerStats.sh", "ServerStats.sh");
        stopPreviousScripts();
        runServerScript();
    }

    @OnOpen
    public void open(final Session session) {
        LOG.info("Opened websocket connection: ", session.getId());
    }

    @OnClose
    public void close(final Session session) {
        LOG.info("Closed websocket connection: ", session.getId());
    }

    @OnMessage
    public void handleMessage(final String message, final Session session) {
        if (RUN_SCRIPT.equals(message)) {
            try {
                final String result = getServerScriptResult();
                session.getBasicRemote().sendText(result);
            } catch (IOException e) {
                LOG.error("Issue sending data to websocket: ", e);
            }
        }
    }

    @OnError
    public void onError(final Throwable throwable) {
        LOG.error("Issue with websocket connection: ", throwable);
    }

    public static final String copyScriptToTempDir(final String inputFilePath,
            final String outputFileName) {
        try (InputStream inputStream = WebSocket.class.getResourceAsStream(inputFilePath)) {
            if (inputStream != null) {
                final String tempDirectory = System.getProperty("java.io.tmpdir");
                final File tempFile = new File(tempDirectory + SEP + outputFileName);
                Files.copy(inputStream, tempFile.toPath(), StandardCopyOption.REPLACE_EXISTING);
                if (!tempFile.setExecutable(true)) {
                    LOG.error("Failed to make temp file executable.");
                }
                return tempFile.getPath();
            }
        } catch (IOException e) {
            LOG.error("Issue copying file to temp directory: ", e);
        }
        return "";
    }

    private static final String stopPreviousScripts() {
        try {
            LOG.info("Stop Scripts");
            final ProcessBuilder processBuilder = new ProcessBuilder("pkill", "-f", "\\/tmp\\/ServerStats.sh");
            Process process = processBuilder.start();
            int result = process.waitFor();
            if(result != 0) {
                throw new InterruptedException();
            }
        } catch (IOException | InterruptedException e) {
            LOG.error("Issue running script: ", e);
            Thread.currentThread().interrupt();
        }
        return "";
    }

    private static final String runServerScript() {
        try {
            LOG.info("Run Script");
            final String tempDirectory = System.getProperty("java.io.tmpdir");
            final File tempFile = new File(tempDirectory + "/ServerStats.sh");
            final ProcessBuilder processBuilder = new ProcessBuilder(tempFile.getAbsolutePath());
            processBuilder.directory(new File(tempDirectory));
            processBuilder.start();
        } catch (IOException e) {
            LOG.error("Issue running script: ", e);
        }
        return "";
    }

    private final String getServerScriptResult() {
        String retVal = "";
        try {
            final String tempDirectory = System.getProperty("java.io.tmpdir");
            final File tempFile = new File(tempDirectory + "/ServerStats.txt");
            retVal = new String(Files.readAllBytes(tempFile.toPath()), StandardCharsets.UTF_8.name());
            // LOG.info(retVal);
        } catch (IOException e) {
            LOG.error("Issue reading script: ", e);
        }
        return retVal;
    }
}
