package com.utils.dashboard;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.StandardCopyOption;
import java.util.Timer;
import java.util.TimerTask;
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
    private static final String RUN_SCRIPT = "gimme";
    private static final String SEP = File.separator;
    private static final int BUFFER_SIZE = 1024;

    private String data = "";

    public WebSocket() {
        copyScriptToTempDir("/sh/ServerStats.sh", "ServerStats.sh");
        final Timer timer = new Timer();
        timer.schedule(new RunScript(), 0, 1000);
    }

    public String getData() {
        return this.data;
    }
    
    public void setData(final String data) {
      this.data = data;
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
                session.getBasicRemote().sendText(this.getData());
            } catch (IOException e) {
                LOG.error("Issue sending data to websocket: ", e);
            }
        }
    }

    @OnError
    public void onError(final Throwable throwable) {
        LOG.error("Issue with websocket connection: ", throwable);
    }

    public String copyScriptToTempDir(final String inputFilePath, final String outputFileName) {
        try (InputStream inputStream = this.getClass().getResourceAsStream(inputFilePath)) {
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

    public class RunScript extends TimerTask {

        private final Logger LOG = LoggerFactory.getLogger(RunScript.class);

        public RunScript() {
            // Intentionally left blank
        }

        @Override
        public void run() {
            final String result = runServerScript();
            setData(result);
        }

        private String runServerScript() {
            try {
                // Run server stats script
                final String tempDirectory = System.getProperty("java.io.tmpdir");
                final File tempFile = new File(tempDirectory + "/ServerStats.sh");
                final ProcessBuilder processBuilder = new ProcessBuilder("./" + tempFile.getName());
                processBuilder.directory(new File(tempDirectory));
                final Process process = processBuilder.start();
                process.waitFor();

                return getServerScriptResult(process);
            } catch (IOException | InterruptedException e) {
                LOG.error("Issue running script: ", e);
                // Thread.currentThread().interrupt();
            }
            return "";
        }

        private String getServerScriptResult(final Process process) {
            // Get output from script
            try (InputStream inputStream = process.getInputStream()) {
                final ByteArrayOutputStream result = new ByteArrayOutputStream();
                final byte[] buffer = new byte[BUFFER_SIZE];
                int length = inputStream.read(buffer);
                while (length != -1) {
                    result.write(buffer, 0, length);
                    length = inputStream.read(buffer);
                }
                return result.toString(StandardCharsets.UTF_8.name());
            } catch (IOException e) {
                LOG.error("Issue getting output from script: ", e);
            }
            return "";
        }
    }
}
