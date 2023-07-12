utils = import_module("github.com/kurtosis-tech/mev-package/lib/utils.star")
mev_relay_module = import_module("github.com/kurtosis-tech/mev-package/lib/mev_relay_launcher.star")
mev_flood_module = import_module("github.com/kurtosis-tech/mev-package/lib/mev_flood_launcher.star")
mev_boost_module = import_module("github.com/kurtosis-tech/mev-package/lib/mev_boost_launcher.star")


VALIDATOR_SERVICE_NAME = "cl-client-0-validator"
MEV_BOOST_SERVICE_NAME_PREFIX = "mev-boost-"
MEV_BOOST_SHOULD_CHECK_RELAY = True

def launch_mev(plan, el_client_context, cl_client_context, network_params):
    validators_root = utils.get_genesis_validators_root(plan, VALIDATOR_SERVICE_NAME)
    el_uri = "http://{0}:{1}".format(el_client_context.ip_addr, el_client_context.rpc_port_num)
    mev_flood_module.launch_mev_flood(plan, el_uri)
    
    beacon_uri = ["http://{0}:{1}".format(cl_client_context.ip_addr, cl_client_context.http_port_num)]
    beacon_uris = ",".join(beacon_uri)
    beacon_service_name = cl_client_context.beacon_service_name

    epoch_recipe = GetHttpRequestRecipe(
        endpoint = "/eth/v1/beacon/blocks/head",
        port_id = HTTP_PORT_ID_FOR_FACT,
        extract = {
            "epoch": ".data.message.body.attestations[0].data.target.epoch"
        }
    )
    plan.wait(recipe = epoch_recipe, field = "extract.epoch", assertion = ">=", target_value = str(network_params["capella_fork_epoch"]), timeout = "20m", service_name = beacon_service_name)
    plan.print("epoch 2 reached, can begin mev stuff")

    relay_endpoint = mev_relay_launcher_module.launch_mev_relay(plan, network_params.network_id, beacon_uris, validator_root)
    mev_flood_module.spam_in_background(plan, el_uri)

    mev_boost_service_name = MEV_BOOST_SERVICE_NAME_PREFIX + str(0)
    mev_boost_launcher = mev_boost_module.new_mev_boost_launcher(MEV_BOOST_SHOULD_CHECK_RELAY, mev_endpoints)
    mev_boost_context = mev_boost_module.launch(plan, mev_boost_launcher, mev_boost_service_name, network_params["network_id"])

    return {
        "mev-boost-context": mev_boost_context,
        "relay_endpoint": relay_endpoint,
    }