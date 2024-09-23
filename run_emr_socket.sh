#!/bin/bash

# docker build -t faiss-perf .

docker rm $(docker ps --all -q -f status=exited)

set -e

emon_enable=0 # 设置为1时启用emon相关代码，设置为0时禁用

if [ "$(cat /sys/kernel/mm/transparent_hugepage/enabled | grep -o '\[always\]')" != "[always]" ]; then \
        echo "Transparent Huge Pages is not set to 'always'. Exiting..."; \
        exit 1; \
fi

mkdir -p output
rm -rf output/*

# 记录起始时间
start_time=$(date +%s)

# 定义核心组
core_groups=(
  "0-7,128-135"
  "8-15,136-143"
  "16-23,144-151"
  "24-31,152-159"
  "32-39,160-167"
  "40-47,168-175"
  "48-55,176-183"
  "56-63,184-191"
)

# 定义容器编号
container_id=1

# 定义 DNNL_ENABLE 的值
DNNL_ENABLE=0  # 或者根据需要设置为 0

# 存储容器 ID 的数组
container_ids=()

for cores in "${core_groups[@]}"; do
  # 启动容器，并获取容器 ID
  cid=$(docker run --cpuset-cpus="$cores" --memory="16g" \
  --name "faiss-perf-$container_id" -d \
  -v $(pwd)/output:/output \
  -v $(pwd)/emon_data:/emon_data \
  -v /home/xtang/faiss-docker/faiss-1.8.0/tutorial/python/1-Flat.py:/home/app/faiss/tutorial/python/1-Flat.py \
  -e CONTAINER_ID="$container_id" \
  faiss-perf \
  sh -c "DNNL_ENABLE=${DNNL_ENABLE} python3 /home/app/faiss/tutorial/python/1-Flat.py > /output/${container_id}.log 2>&1")

  echo "Started container faiss-perf-$container_id with cores $cores and DNNL_ENABLE=${DNNL_ENABLE}"

  # 将容器 ID 添加到数组
  container_ids+=("$cid")

  ((container_id++))
done

# 存储 docker wait 命令的 PID 的数组
wait_pids=()

# 等待所有容器完成
for cid in "${container_ids[@]}"; do
  docker wait "$cid" &
  # 获取后台进程的 PID
  wait_pids+=("$!")
done

if [ "$emon_enable" -eq 1 ]; then
  rm -rf emon_data/emr_socket_wo_amx.xlsx
  rm -rf summary.xlsx
  rm -rf emon.dat
  rm -rf *.csv
  echo "start emon...."
  emon -collect-edp > emon.dat &
fi

# 等待所有 docker wait 命令完成
for pid in "${wait_pids[@]}"; do
  wait "$pid"
done

# 记录结束时间
end_time=$(date +%s)

if [ "$emon_enable" -eq 1 ]; then
  echo "stop emon...."
  emon -stop
  emon -process-pyedp /opt/intel/sep/config/edp/pyedp_config.txt
  mv summary.xlsx emon_data/emr_socket_wo_amx.xlsx
  rm -rf emon.dat
  rm -rf *.csv
fi

# 计算并输出运行总耗时
duration=$((end_time - start_time))
echo "Total duration: ${duration} seconds"

for cid in "${container_ids[@]}"; do
  docker rm "$cid"
done
