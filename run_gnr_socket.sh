#!/bin/bash

docker build -t faiss-perf .

docker rm $(docker ps --all -q -f status=exited)

set -e

mkdir -p output
rm -rf output/*

# 记录起始时间
start_time=$(date +%s)

# 定义核心组
core_groups=(
  "0-7,256-263"
  "8-15,264-271"
  "16-23,272-279"
  "24-31,280-287"
  "32-42,288-298"
  "43-50,299-306"
  "51-58,307-314"
  "59-66,315-322"
  "67-74,323-330"
  "75-84,331-340"
  "85-92,341-348"
  "93-100,349-356"
  "101-108,357-364"
  "109-116,365-372"
  "117-127,373-383"
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
    -v /home/xtang/faiss-docker/faiss-1.8.0/tutorial/python/1-Flat.py:/home/app/faiss/tutorial/python/1-Flat.py \
    faiss-perf \
    sh -c "DNNL_ENABLE=${DNNL_ENABLE} python3 /home/app/faiss/tutorial/python/1-Flat.py > /output/${container_id}.log 2>&1")

  echo "Started container faiss-perf-$container_id with cores $cores and DNNL_ENABLE=${DNNL_ENABLE}"

  # 将容器 ID 添加到数组
  container_ids+=("$cid")

  ((container_id++))
done

# 等待所有容器完成
for cid in "${container_ids[@]}"; do
  docker wait "$cid" &
done

# 等待所有 docker wait 命令完成
wait

# 记录结束时间
end_time=$(date +%s)

# 计算并输出运行总耗时
duration=$((end_time - start_time))
echo "Total duration: ${duration} seconds"

for cid in "${container_ids[@]}"; do
  docker rm "$cid"
done
