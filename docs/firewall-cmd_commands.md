# firewall-cmd commands

List available ports
```
firewall-cmd --list-ports
```

List everything
```
firewall-cmd --list-all
```

Reload firewalld
```
sudo firewall-cmd --reload
```

Allow port 80 permanently
```
sudo firewall-cmd --add-port=80/tcp --permanent
```

Allow http service
```
sudo firewall-cmd --add-service=http --permanent
```