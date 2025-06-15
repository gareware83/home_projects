#include <stdio.h>
#include "xil_io.h"
#include "xuartlite.h"
#include "xuartlite_l.h"
#include "xparameters.h"
#include "string.h"


#define UART_DEVICE_ID XPAR_UARTLITE_0_DEVICE_ID
#define INPUT_LENGTH 8
#define CMD_LENGTH 8

XUartLite UartLite;

void process_command(char *cmd) {
    // Example: match a known command
	// Example: send back confirmation message
    //char cmd_buffer[INPUT_LENGTH + 1]; // +1 for null-terminator

	memset(cmd,0, sizeof(INPUT_LENGTH + 1));
	// Null terminate and process
    cmd[INPUT_LENGTH] = '\0';

    const char *msg = "\nInput Received: \n\r";

	for (int j = 0; msg[j] != '\0'; j++)
	{
	    XUartLite_SendByte(UartLite.RegBaseAddress, msg[j]);
	}

	for (int j = 0; j < INPUT_LENGTH; j++)
	{
	    XUartLite_SendByte(UartLite.RegBaseAddress, cmd[j]);
	}

	XUartLite_SendByte(UartLite.RegBaseAddress, '\n');

    //sprintf(cmd_buffer, "%u", cmd);

    if (strncmp(cmd, "CMD_ONE", CMD_LENGTH) == 0) {
        print("\nYou entered CMD_ONE\n\r");
        Xil_Out32(0x44A00004, 0x1);
    	//XUartLite_SendByte(UartLite.RegBaseAddress, u8 Data);
    } else if (strncmp(cmd, "CMD_TWO", CMD_LENGTH) == 0) {
    	print("You entered CMD_TWO");
    } else {
    	print("\nUnknown Command");
    }
}

int main() {
    char cmd_buf[CMD_LENGTH + 1];
    int index = 0;

    XUartLite_Initialize(&UartLite, UART_DEVICE_ID);
    print("\nProgram Started\n\r");
    while (1) {
    	while (index < CMD_LENGTH - 1)
    	{
            if (XUartLite_IsReceiveEmpty(UartLite.RegBaseAddress) == 0) {
                char c = XUartLite_RecvByte(UartLite.RegBaseAddress);
                // Echo character back
                XUartLite_SendByte(UartLite.RegBaseAddress, c);
                cmd_buf[index++] = c;

                if (index >= CMD_LENGTH - 1) {
                    process_command(cmd_buf);
                    index = 0; // reset for next command

                }
            }
        }
    }

    return 0;
}

/*int main() {
    int Status;
    u8 input_buffer[INPUT_LENGTH + 1]; // +1 for null-terminator
    int i = 0;
    u8 ch;

    // Initialize UART
    Status = XUartLite_Initialize(&UartLite, UART_DEVICE_ID);
    if (Status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    printf("%s %d\n\r", "UART Initialized ", Status);

    // Main input loop
    while (1) {
        i = 0;
        //memset(input_buffer, 0, sizeof(input_buffer));

        while (i < INPUT_LENGTH) {
            if (!XUartLite_IsReceiveEmpty(UartLite.RegBaseAddress)) {
                ch = XUartLite_RecvByte(UartLite.RegBaseAddress);

                // Echo character back
                XUartLite_SendByte(UartLite.RegBaseAddress, ch);

                // Store into buffer
                input_buffer[i++] = ch;
            }
        }

        // Null terminate and process
        input_buffer[INPUT_LENGTH] = '\0';

        // Example: send back confirmation message
        const char *msg = "\nInput received: ";
        for (int j = 0; msg[j] != '\0'; j++)
            XUartLite_SendByte(UartLite.RegBaseAddress, msg[j]);

        for (int j = 0; j < INPUT_LENGTH; j++)
            XUartLite_SendByte(UartLite.RegBaseAddress, input_buffer[j]);

        XUartLite_SendByte(UartLite.RegBaseAddress, '\n');
    }

    return 0;
}*/

