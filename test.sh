#!/bin/bash 

# set -x

readonly BASE_URL=https://speedtest.edgecompute.app/
#   readonly BASE_URL=https://speedtest.global.ssl.fastly.net/
readonly TEST_TYPE=$1
readonly SIZE=$2
readonly BOLD_TEXT=$(tput bold 2>/dev/null)
readonly NORMAL_TEXT=$(tput sgr0 2>/dev/null)

cleanup_old_files() {
    rm -rf curl.out.g*
}

download_data() {
    local size=$1

    case $size in
        10M)
            file_too_small
            ;;
        20M)
            file_too_small
            ;;
        50M)
            local url="${BASE_URL}__down?bytes=$((50 * 1024 * 1024))"
            ;;
        100M)
            local url="${BASE_URL}__down?bytes=$((100 * 1024 * 1024))"
            ;;
        200M)
            local url="${BASE_URL}__down?bytes=$((200 * 1024 * 1024))"
            ;;
        500M)
            local url="${BASE_URL}__down?bytes=$((500 * 1024 * 1024))"
            ;;
        1G)
            local url="${BASE_URL}__down?bytes=$((1000 * 1024 * 1024))"
            ;;
        *)
            print_usage
    esac

    echo "${BOLD_TEXT}Beginning download of ${size} test file...${NORMAL_TEXT}"

    curl -w "\nDownload size:\t%{size_download}\nAverage speed:\t%{speed_download}\n\n" -L -o /dev/null "${url}" 2>&1 \
        | tr '\r' '\n' > curl.out

    grep "Download size" curl.out | awk '{print $1,$2,$3 / 1048576,"MB"}'

}

upload_data() {
    local size=$1
    local url="${BASE_URL}__up"

    case $size in
        5M)
            local file_size=$((5 * 1024))
            ;;
        10M)
            local file_size=$((10 * 1024))
            ;;
        20M)
            local file_size=$((20 * 1024))
            ;;
        50M)
            local file_size=$((50 * 1024))
            ;;
        100M)
            file_too_large
            ;;
        200M)
            file_too_large
            ;;
        500M)
            file_too_large
            ;;
        1G)
            file_too_large
            ;;
        *)
            print_usage
    esac

    # Create test file
    echo "${BOLD_TEXT}Creating ${size} test file...${NORMAL_TEXT}"

    dd if=/dev/zero of=upload.bin  bs=1024  count=${file_size} > /dev/null 2>&1

    echo "${BOLD_TEXT}Beginning upload of ${size} test file...${NORMAL_TEXT}"

    curl -w '\nUpload size:\t%{size_upload}\nAverage speed:\t%{speed_upload}\n\n' -F 'data=@upload.bin' "${url}" 2>&1 \
        | tr '\r' '\n' > curl.out

    # Clean up synthetic file after
    rm upload.bin

    grep "Upload size" curl.out | awk '{print $1,$2,$3 / 1048576,"MB"}'

}

generate_report() {
    ./curl_data.py curl.out 
    echo "Bandwidth graph..."
    ./imgcat curl.out.png
}

run_tests() {
    local test_type=${TEST_TYPE}
    local size=${SIZE}

    case $test_type in 
        up)
            upload_data $size
            ;;
        down)
            download_data $size 
            ;;
        *)  
            print_usage
            ;;
    esac
            

}

show_average_speed() {
    grep "Average speed" curl.out | awk '{print $1,$2,$3 / 125000,"Mbit/sec"}'
}

print_usage() {
    echo "Usage: $(basename $0) up [5M|10M|20M|50M] | down [100M|200M|500M|1G]"
    exit 1
}

show_error() {
    echo "${BOLD_TEXT}Missing components for report generation. Please run './requirements.sh'${NORMAL_TEXT}"
    exit 1
}

file_too_large() {

    echo "${BOLD_TEXT}"
    echo "****************************************"
    echo "ERROR: File is too large for upload test"
    echo "****************************************"
    echo ""
    exit 1
}

file_too_small() {

    echo "${BOLD_TEXT}"
    echo "***************************************************"
    echo "ERROR: File is too small for accurate download test"
    echo "***************************************************"
    echo ""
    exit 1
}

main() {
    local test_type=${TEST_TYPE}
    local size=${SIZE}

    cleanup_old_files

    run_tests $test_type $size

    show_average_speed

    generate_report || show_error
}

main $TEST_TYPE $SIZE