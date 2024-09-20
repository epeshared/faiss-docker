import os
import re

# 定义日志目录
log_dir = 'output'

# 初始化变量
total_nq = 0
search_times = []

# 定义正则表达式模式
nq_pattern = re.compile(r'nq:\s*(\d+)')
avg_time_pattern = re.compile(r'Avg\. \[(\d+\.\d+) s\] search time')

# 遍历日志目录下的所有文件
for filename in os.listdir(log_dir):
    filepath = os.path.join(log_dir, filename)
    if os.path.isfile(filepath):
        with open(filepath, 'r') as f:
            content = f.read()
            # 提取 nq 值
            nq_match = nq_pattern.search(content)
            if nq_match:
                nq_value = int(nq_match.group(1))
                total_nq += nq_value
            else:
                print(f'Warning: nq not found in {filename}')
                continue
            # 提取 Avg. search time 值
            avg_time_match = avg_time_pattern.search(content)
            if avg_time_match:
                avg_time_value = float(avg_time_match.group(1))
                search_times.append(avg_time_value)
            else:
                print(f'Warning: Avg. search time not found in {filename}')
                continue

# 计算平均 search time
if search_times:
    avg_search_time = sum(search_times) / len(search_times)
else:
    print('No search times found.')
    avg_search_time = 0

# 计算累计的 nq 值除以平均的 search time
if avg_search_time > 0:
    result = total_nq / avg_search_time
    print(f'Total nq: {total_nq}')
    print(f'Average search time: {avg_search_time:.3f} s')
    print(f'Result (Total nq / Average search time): {result:.3f}')
else:
    print('Average search time is zero or not available.')
