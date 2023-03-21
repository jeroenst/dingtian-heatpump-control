# Input List
# 1 = Thermostat Livingroom
# 2 = Thermostat Kitchen
# 3 = Thermostat Appartment
# 7 = Cool/Heat Switch
# 8 = Gas Boiler Override Switch

# Output List
# 1 = valve/pump livingroom
# 2 = valve/pump kitchen
# 3 = valve/pump appartment
# 4 = Gas Boiler Request Heat (when ch_override is active)
# 5 = Heatpump Request Heat
# 6 = Heatpump Request Cool
# 7 = Heatpump Request DHW
var ch_override_old = false;
var mode_heat_old = false;
var initialized = false;
var pump_run = false

# run_pump sets variable pump_run on for 30 seconds each 24 hours
# to prevent the pumps getting stuck
def run_pump()
    if (pump_run)
        tasmota.set_timer(86400000,run_pump) 
        pump_run = false
    else
        tasmota.set_timer(30000,run_pump)
        pump_run = true
    end
end

# control_house_climate runs every second to check inputs
# and control outputs for heating or cooling different zones
def control_house_climate()
    var inputs = tasmota.get_switches()
    var outputs = tasmota.get_power()
    var thermostat_livingroom = !inputs[0]
    var thermostat_kitchen = !inputs[1]
    var thermostat_appartment = !inputs[2]
    var mode_heat = inputs[6]
    var ch_override = !inputs[7]

    var thermostat_active = false



    if (ch_override != ch_override_old || !initialized)
        if (ch_override)
            print ("Gas Boiler Override Activated")
        else
            print ("Gas Boiler Override Deactivated")
        end
        ch_override_old = ch_override
    end

    if (mode_heat != mode_heat_old || !initialized)
        if (mode_heat)
            print ("Heating Mode Activated")
        else
            print ("Cooling Mode Deactivated")
        end
        mode_heat_old = mode_heat
    end


    #print(inputs)

    if (thermostat_livingroom == mode_heat)
        thermostat_active = true
        if (outputs[0] == false) 
            print ("Livingroom Active")
            tasmota.set_power(0, true)
        end
    else
        if (pump_run)
            if (outputs[0] == false)
                print ("Livingroom Pump Run")
                tasmota.set_power(0, true)
            end
        else 
            if (outputs[0] == true) 
                print ("Livingroom Deactivated")
                tasmota.set_power(0, false)
            end
        end
    end
    

    if (thermostat_kitchen == mode_heat)
        thermostat_active = true
        if (outputs[1] == false) 
            print ("Kitchen Activated")
            tasmota.set_power(1, true)
        end
    else
        if (pump_run)
            if (outputs[1] == false)
                print ("Kitchen Pump Run")
                tasmota.set_power(1, true)
            end
        else 
            if (outputs[1] == true) 
                print ("Kitchen Deactivated")
                tasmota.set_power(1, false)
            end
        end
    end
    
    if (thermostat_appartment == mode_heat)
        thermostat_active = true
        if (outputs[2] == false) 
            print ("Appartment Activated")
            tasmota.set_power(2, true)
        end
    else
        if (pump_run)
            if (outputs[2] == false)
                print ("Appartment Pump Run")
                tasmota.set_power(2, true)
            end
        else 
            if (outputs[2] == true) 
                print ("Appartment Deactivated")
                tasmota.set_power(2, false)
            end
        end
    end
    
    if (thermostat_active)
        if (ch_override)
            if (outputs[4] == true) 
                tasmota.set_power(4, false)
            end
            if (outputs[5] == true) 
                tasmota.set_power(5, false)
            end
            if (mode_heat)
                if (outputs[3] == false) 
                    print ("Requesting heat from Gas Boiler")
                    tasmota.set_power(3, true)
                end
            end
        else
            if (outputs[3] == true) 
                tasmota.set_power(3, false)
            end
            if (mode_heat)
                if (outputs[4] == false) 
                    print ("Requesting heat from Heat Pump")
                    tasmota.set_power(4, true)
                end
                if (outputs[5] == true) 
                    tasmota.set_power(5, false)
                end
            else
                if (outputs[4] == true) 
                    tasmota.set_power(4, false)
                end
                if (outputs[5] == false) 
                    print ("Requesting cool from Heat Pump")
                    tasmota.set_power(5, true)
                end
            end
        end
    else
        if (outputs[4] == true) 
            print ("Stopping heat from Heat Pump")
            tasmota.set_power(4, false)
        end
        if (outputs[5] == true) 
            print ("Stopping cool from Heat Pump")
            tasmota.set_power(5, false)
        end
        if (outputs[6] == true) 
            print ("Stopping heat from Gas Boiler")
            tasmota.set_power(6, false)
        end
    end
    
    #print(outputs)

    gpio.pin_mode(2,gpio.OUTPUT)
    var led = gpio.digital_read(2)
    if (led == 1) led = 0
    else led = 1
    end
    gpio.digital_write(2,led)
    tasmota.set_timer(1000,control_house_climate)

    initialized=true
end


control_house_climate()
run_pump()
