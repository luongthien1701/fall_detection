from collections import deque
from collections import defaultdict

queue = deque()
device_queues = defaultdict(deque)
devices = {}

device_status = "offline"
last_update = None
history = []

last_alert_time = 0
device_last_alert_time = defaultdict(float)
