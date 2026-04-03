import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
import random


async def wait_cycles(dut, cycles):
    for _ in range(cycles):
        await RisingEdge(dut.clk)


async def wait_until_high(dut, signal, max_cycles, signal_name):
    for _ in range(max_cycles):
        if int(signal.value) == 1:
            return
        await RisingEdge(dut.clk)
    assert False, f"Timeout waiting for {signal_name}"


async def wait_tick_16x(dut, ticks):
    seen = 0
    while seen < ticks:
        await RisingEdge(dut.clk)
        if int(dut.baud_tick_16x.value) == 1:
            seen += 1


async def drive_uart_frame(dut, data_byte, parity_en, parity_odd, inject_bad_parity=False):
    bits = [0]
    bits.extend((data_byte >> i) & 1 for i in range(8))

    if parity_en:
        parity_bit = (bin(data_byte).count("1") & 1)
        if parity_odd:
            parity_bit ^= 1
        if inject_bad_parity:
            parity_bit ^= 1
        bits.append(parity_bit)

    bits.append(1)

    dut.rx_serial.value = 1
    await wait_tick_16x(dut, 2)

    for bit in bits:
        dut.rx_serial.value = bit
        await wait_tick_16x(dut, 16)

    dut.rx_serial.value = 1
    await wait_tick_16x(dut, 16)

async def reset_dut(dut):
    """Reset the DUT."""
    dut.rst_n.value = 0
    dut.rx_serial.value = 1 # Idle state for UART
    dut.tx_start.value = 0
    dut.tx_data.value = 0
    dut.parity_en.value = 0
    dut.parity_odd.value = 0
    
    await wait_cycles(dut, 5)
        
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

@cocotb.test()
async def test_uart_loopback(dut):
    """Test UART TX to RX loopback with random data."""
    
    # Start a 50MHz clock (20ns period)
    clock = Clock(dut.clk, 20, units="ns")
    cocotb.start_soon(clock.start())
    
    await reset_dut(dut)

    seed = 20260403
    random.seed(seed)
    dut._log.info(f"Using random seed: {seed}")
    
    # Connect TX to RX for loopback testing
    # We'll use a background coroutine to continuously forward tx_serial to rx_serial
    async def loopback():
        while True:
            await RisingEdge(dut.clk)
            dut.rx_serial.value = dut.tx_serial.value
            
    cocotb.start_soon(loopback())
    
    # Test parameters
    num_tests = 20
    
    for _ in range(num_tests):
        # Generate random byte
        test_byte = random.randint(0, 255)
        
        # Wait until TX is not busy
        while dut.tx_busy.value == 1:
            await RisingEdge(dut.clk)
            
        # Start transmission
        dut.tx_data.value = test_byte
        dut.tx_start.value = 1
        await RisingEdge(dut.clk)
        dut.tx_start.value = 0
        
        dut._log.info(f"Sending byte: {hex(test_byte)}")
        
        # Wait for RX valid
        await wait_until_high(dut, dut.rx_valid, max_cycles=50000, signal_name="rx_valid")
                
        # Check received data
        received_byte = int(dut.rx_data.value)
        dut._log.info(f"Received byte: {hex(received_byte)}")
        
        assert received_byte == test_byte, f"Data mismatch! Sent: {hex(test_byte)}, Received: {hex(received_byte)}"
        assert dut.framing_error.value == 0, "Framing error detected!"
        assert dut.parity_error.value == 0, "Parity error detected!"
        
        # Wait a bit before next transmission
        await wait_cycles(dut, 100)

    dut._log.info("Loopback test completed successfully!")

@cocotb.test()
async def test_uart_parity(dut):
    """Test UART with parity enabled."""
    
    clock = Clock(dut.clk, 20, units="ns")
    cocotb.start_soon(clock.start())
    
    await reset_dut(dut)
    
    # Enable parity (Even parity)
    dut.parity_en.value = 1
    dut.parity_odd.value = 0
    
    async def loopback():
        while True:
            await RisingEdge(dut.clk)
            dut.rx_serial.value = dut.tx_serial.value
            
    cocotb.start_soon(loopback())

    for parity_odd in (0, 1):
        dut.parity_odd.value = parity_odd
        for test_byte in (0x00, 0x55, 0xA3, 0xFF):
            while dut.tx_busy.value == 1:
                await RisingEdge(dut.clk)

            dut.tx_data.value = test_byte
            dut.tx_start.value = 1
            await RisingEdge(dut.clk)
            dut.tx_start.value = 0

            await wait_until_high(dut, dut.rx_valid, max_cycles=50000, signal_name="rx_valid")

            assert int(dut.rx_data.value) == test_byte
            assert dut.parity_error.value == 0, "Unexpected parity error!"
            assert dut.framing_error.value == 0, "Unexpected framing error!"
    
    dut._log.info("Parity test completed successfully!")


@cocotb.test()
async def test_uart_bad_parity_sets_error(dut):
    """Inject a frame with incorrect parity and verify parity_error is asserted."""

    clock = Clock(dut.clk, 20, units="ns")
    cocotb.start_soon(clock.start())

    await reset_dut(dut)

    dut.parity_en.value = 1
    dut.parity_odd.value = 0

    test_byte = 0x3C
    await drive_uart_frame(
        dut,
        data_byte=test_byte,
        parity_en=1,
        parity_odd=0,
        inject_bad_parity=True,
    )

    await wait_until_high(dut, dut.rx_valid, max_cycles=50000, signal_name="rx_valid")

    assert int(dut.rx_data.value) == test_byte, "RX data mismatch for bad parity frame"
    assert int(dut.parity_error.value) == 1, "Expected parity_error to assert for bad parity"
    assert int(dut.framing_error.value) == 0, "Framing error should remain low for parity-only fault"
