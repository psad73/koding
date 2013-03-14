#
# Cookbook Name:: users
# Recipe:: sysadmins
#
# Copyright 2011, Eric G. Wolfe
# Copyright 2009-2011, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Searches data bag "users" for groups attribute "sysadmin".
# Places returned users in Unix group "sudo" with GID 27.

package "libshadow-ruby1.8" do
    action :install
end

case node['platform_family']
when "rhel", "cloudlinux"
	users_manage "sysadmin" do
	  group_name "wheel"
	  group_id 10
	  action [ :remove, :create ]
	end
when "debian"
	users_manage "sysadmin" do
	  group_name "sudo"
	  group_id 27
	  action [ :remove, :create ]
	end
end
