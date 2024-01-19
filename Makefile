TARGET         = py_canister.sh
update_cmd     = ./update_template.sh 
update_cmd_opt = -v

SRC_DIR  = input

all: $(TARGET)

$(TARGET): $(addprefix $(SRC_DIR)/$(TARGET)/, $(filter-out %~ #%, $(notdir $(wildcard $(SRC_DIR)/$(TARGET)/*))))
	$(update_cmd) $(update_cmd_opt) $@
