PATH_TO_PARSED_BEACON_STATE = "/genesis/output/parsedBeaconState.json"

def get_genesis_validators_root(plan, validator_service_name):
    response = plan.exec(
        service_name = validator_service_name,
        recipe = ExecRecipe(
            command = ["/bin/sh", "-c", "cat {0} | grep genesis_validators_root | grep -oE '0x[0-9a-fA-F]+'".format(PATH_TO_PARSED_BEACON_STATE)],
        )
    )

    return response["output"]