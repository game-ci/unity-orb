check_env_variable_empty() {
    if [ -z "$ACTIVATION_ULF_VAR_NAME" ]; then 
        echo "${ACTIVATION_ULF_VAR_NAME} is missing. You must provide the base64 encoded ULF license file contents."
        exit 1
    fi
}

decode_ulf() {
    DECODED_ULF=$(echo "$ACTIVATION_ULF_VAR_NAME" | base64 --decode)
}

check_env_variable_empty
decode_ulf

# Saving decoded ULF to file and activating unity
# Returning true after activation to bypass misleading exit code 1
echo "$DECODED_ULF" > /root/Unity_lic.ulf
/opt/unity/Editor/Unity -batchmode -manualLicenseFile /root/Unity_lic.ulf -logfile /dev/stdout || true