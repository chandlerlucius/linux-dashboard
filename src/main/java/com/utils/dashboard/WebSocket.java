package com.utils.dashboard;

import java.io.ByteArrayOutputStream;
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

@ServerEndpoint("/websocket")
public class WebSocket {

    private static final Logger LOG = LoggerFactory.getLogger(WebSocket.class);

    public WebSocket() {
        copyScriptToTempDir("/sh/ServerStats.sh", "ServerStats.sh");
    }

    @OnOpen
    public void open(final Session session) {
        LOG.info("Closed websocket connection: ", session.getId());
    }

    @OnClose
    public void close(final Session session) {
        LOG.info("Opened websocket connection: ", session.getId());
    }

    @OnMessage
    public void handleMessage(final String message, final Session session) {
        if(message.equals("gimme")) {
            try {
                final String data = runServerScript();
                session.getBasicRemote().sendText(data);
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
                final File tempFile = new File(tempDirectory + "/" + outputFileName);
                Files.copy(inputStream, tempFile.toPath(), StandardCopyOption.REPLACE_EXISTING);
                tempFile.setExecutable(true);
                return tempFile.getPath();
            }
        } catch (IOException e) {
            LOG.error("Issue copying file to temp directory: ", e);
        }
        return "";
    }

    private static String runServerScript() {
        try {
            // Run server stats script
            final String tempDirectory = System.getProperty("java.io.tmpdir");
            final File tempFile = new File(tempDirectory + "/ServerStats.sh");
            final ProcessBuilder processBuilder = new ProcessBuilder("./" + tempFile.getName());
            processBuilder.directory(new File(tempDirectory));
            final Process process = processBuilder.start();
            process.waitFor();

            // Get output from script
            try (InputStream inputStream = process.getInputStream()) {
                final ByteArrayOutputStream result = new ByteArrayOutputStream();
                final byte[] buffer = new byte[1024];
                int length = inputStream.read(buffer);
                while (length != -1) {
                    result.write(buffer, 0, length);
                    length = inputStream.read(buffer);
                }
                return result.toString(StandardCharsets.UTF_8.name());
            } catch (IOException e) {
                LOG.error("Issue getting output from script: ", e);
            }
        } catch (IOException | InterruptedException e) {
            LOG.error("Issue running script: ", e);
        }
        return "";
    }
}
