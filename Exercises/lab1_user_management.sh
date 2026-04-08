# Create the teams groups.
groupadd -g 2001 dev
groupadd -g 2002 ops
groupadd -g 2003 management
groupadd -g 2010 shared

grep -E 'dev|ops|management|shared' /etc/group

# Create the users and add them to the appropriate groups.
# Devs group
useradd -m -s /bin/bash -g dev -G shared -c "Alice -Senior developer" alice
useradd -m -s /bin/bash -g dev -G shared -c "Bob - developer" bob
useradd -m -s /bin/bash -g dev -G shared -c "Charlie -junior developer" charlie

# ops Team
useradd -m -s /bin/bash -g ops -G shared -c "David - Sysadmin" david
useradd -m -s /bin/bash -g ops -G shared -c "Eve - DevOps engineer" eve

# Management Team
useradd -m -s /bin/bash -g management -G shared -c "Frank - Manager" frank

echo "alice:alice123" | chpasswd
echo "bob:bob123" | chpasswd
echo "charlie:charlie123" | chpasswd
echo "david:david123" | chpasswd
echo "eve:eve123" | chpasswd
echo "frank:frank123" | chpasswd

for user in alice bob charlie david eve frank; do
    echo "User: $user"
    id $user
done

# Create directories for each team and set permissions.
mkdir -p /teams/{dev,ops,management,shared}

chown root:dev /teams/dev
chmod 770 /teams/dev
chown root:ops /teams/ops
chmod 770 /teams/ops
chown root:management /teams/management
chmod 770 /teams/management
chown root:shared /teams/shared
chmod 775 /teams/shared

ls -la /teams