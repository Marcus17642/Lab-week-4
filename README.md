# 4640-w4-lab-start-w25

Marcus Su, Rafeel Geelani, Tuan Nguyen


# Generate ssh key


ssh-keygen -t rsa -b 4096 -f ~/.ssh/web-key -N ""

# copy the public key with cat (this will be put into the cloud-config file)

cat ~/.ssh/web-key.pub

now copy the output and put it into the ssh authorized key part of the cloud config file.

now put nginx and nmap into the packages of cloud config like this.

```
packages:
  - nginx
  - nmap
```

also add the systemctl commands for nginx so you dont have to start and enable nginx manually
```
runcmd:
  - systemctl enable nginx
  - systemctl start nginx
```

After the main.tf is done, use these terraform commands

```
terraform init
#(makes a terraform directory with config files like git init )

terraform fmt
#(formats the main.tf file)

terraform validate
#(checks for errors in the main.tf file)

terraform plan
#(shows what Terraform will do when you run terraform apply)

terraform apply
#(runs the main.tf file)
```

after doing terraform apply, you should see the dns and public ip of the instance.
Copy the dns and use ssh -i to connect to the instance.

ssh -i ~/.ssh/web-key web@<public_dns>

You can also see visit see the nginx running on the instance by visiting the dns with http

http://<public_dns>
