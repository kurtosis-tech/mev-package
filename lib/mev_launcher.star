utils = import_module("github.com/kurtosis-tech/mev-package/lib/utils.star")
mev_relay_module = import_module("github.com/kurtosis-tech/mev-package/lib/mev_relay_launcher.star")
mev_flood_module = import_module("github.com/kurtosis-tech/mev-package/lib/mev_flood_launcher.star")
mev_boost_module = import_module("github.com/kurtosis-tech/mev-package/lib/mev_boost_launcher.star")


VALIDATOR_SERVICE_NAME = "cl-client-0-validator"
MEV_BOOST_SERVICE_NAME_PREFIX = "mev-boost-"
MEV_BOOST_SHOULD_CHECK_RELAY = True
HTTP_PORT_ID_FOR_FACT = "http"

def launch_mev(plan, el_client_context, cl_client_context, network_params):
    validators_root = utils.get_genesis_validators_root(plan, VALIDATOR_SERVICE_NAME)
    el_uri = "http://{0}:{1}".format(el_client_context.ip_addr, el_client_context.rpc_port_num)
    mev_flood_module.launch_mev_flood(plan, el_uri)
    
    beacon_uri = ["http://{0}:{1}".format(cl_client_context.ip_addr, cl_client_context.http_port_num)]
    beacon_uris = ",".join(beacon_uri)
    beacon_service_name = cl_client_context.beacon_service_name

    mev_boost_service_name = MEV_BOOST_SERVICE_NAME_PREFIX + str(0)
    mev_boost_launcher = mev_boost_module.new_mev_boost_launcher(MEV_BOOST_SHOULD_CHECK_RELAY, ["http://0xae1c2ca7bbd6f415a5aa5bb4079caf0a5c273104be5fb5e40e2b5a2f080b2f5bd945336f2a9e8ba346299cb65b0f84c8@mev-relay-api:9062"])
    mev_boost_context = mev_boost_module.launch(plan, mev_boost_launcher, mev_boost_service_name, network_params["network_id"])

    epoch_recipe = GetHttpRequestRecipe(
        endpoint = "/eth/v1/beacon/blocks/head",
        port_id = HTTP_PORT_ID_FOR_FACT,
        extract = {
            "epoch": ".data.message.body.attestations[0].data.target.epoch"
        }
    )
    plan.wait(recipe = epoch_recipe, field = "extract.epoch", assertion = ">=", target_value = str(network_params["capella_fork_epoch"]), timeout = "20m", service_name = beacon_service_name)
    plan.print("epoch {0} reached, can begin mev stuff".format(network_params["capella_fork_epoch"]))

    relay_endpoint = mev_relay_module.launch_mev_relay(plan, network_params["network_id"], beacon_uris, validators_root)
    mev_flood_module.spam_in_background(plan, el_uri)

    return {
        "mev-boost-context": mev_boost_context,
        "relay_endpoint": relay_endpoint,
    }

def get_mev_params():
    mev_url = "http://{0}{1}:{2}".format(MEV_BOOST_SERVICE_NAME_PREFIX, 0, mev_boost_module.FLASHBOTS_MEV_BOOST_PORT)
    el_extra_params = ["--builder",  "--builder.remote_relay_endpoint=http://mev-relay-api:9062", "--builder.beacon_endpoints=http://cl-client-{0}-beacon:4000".format(0), "--builder.bellatrix_fork_version=0x30000038", "--builder.genesis_fork_version=0x10000038", "--builder.genesis_validators_root=0xd1ec305b97bf6336571c2348e4a8bf173684b0cdb7e55f7e6554d51f8478b5a3",  "--miner.extradata=\"Illuminate Dmocratize Dstribute\"", "--miner.algotype=greedy"]
    validator_extra_params = ["--builder-proposals"]
    beacon_extra_params = ["--builder={0}".format(mev_url)]
    mev_builder_image = "h4ck3rk3y/builder"
    beacon_extra_params.append("--always-prepare-payload")
    beacon_extra_params.append("--prepare-payload-lookahead")
    beacon_extra_params.append("12000")


    return el_extra_params, mev_builder_image, validator_extra_params, beacon_extra_params