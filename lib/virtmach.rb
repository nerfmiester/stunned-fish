require 'virtmach/version.rb'

# Add requires for other files you add to your project here, so
# you just need to require this one file in your bin file
class VirtualDrive

def mkDrive
  cmd = "lvcreate -n #{@name} --size #{@size} #{@vgname}"
  if @dryRun
    print "Would run\n\t"
    puts cmd
  else
    system(cmd)
  end
end

def mkPath
  "/dev/#{@vgname}/#{@name}"
end

def rmDrive
  #
  # First check if the device exists.
  #
  drv=mkPath
  cmd = "lvremove -f #{drv}"

  if @dryRun
    print "Would run\n\t"
    puts cmd
  else
    system( cmd )
  end
end

def dump
  puts "Device Name  #{@name}"
  puts "       Size  #{@size}"
  puts "Volume Group #{@vgname}"
  puts "Dry Run      #{@dryRun}"
  puts ""
end
end
class VirtualMachine


  attr :volumeGroup, true
  attr :dryRun, true

  def initialize name,ram=4, cpus=2, boot='cdrom',iso='/root/DiskImages/ubuntu-12.04.1-server-amd64.iso'
    @name=name
    @disks=[]
    @ram=ram
    @cpus=cpus
    @graphics='vnc'
    @cdrom='/root/DiskImages/ubuntu-12.04.1-server-amd64.iso'
    @boot='cdrom'
    @network='network:default'
    @graphics='vnc'
    @network='network:default'
    @os='ubuntuprecise'
    @volumeGroup='VirtualMachines'
    @dryRun = false
  end

  def addDisk name,size
    puts "addDisk #{@dryRun}"
    @disks << VirtualDrive.new( name,size, @volumeGroup, @dryRun)

  end

  def mkMachine
    puts "Creating Virtual Machine"

    exit if machineExists?

    print "\tMachine: #{@name} Does not exist\n"

    @disks.each{ |drive|
      drive.mkDrive
    }
    mkVM

  end

  def rmMachine
    #
    # First check if the machines, exists and is not running.
    #

    drive=[]

    puts "Destroying Virtual Machine"

    cmd = "virsh dumpxml #{@name} " << '| grep "source dev="'

    f=IO.popen( cmd )
    res=f.readlines
    f.close

    if 0 == res.length
      puts "#{@name} is not defined"
      exit 1
    end

    rmVM


    res.each{|line|
      device=line[0..-5].split("'")[1]

      d=device.split('/')

      vg=d[2]
      nm=d[3]

      drive=VirtualDrive.new(nm,0,vg,@dryRun)
      drive.rmDrive

    }

  end

  def dump
    puts "Hostname    #{@name}"
    puts "Disks =================================="
    @disks.each{|disk|
      disk.dump
    }
    puts "========================================"

  end

  private

  def machineExists?
    status = false

    f=IO.popen( "virsh list --all" )
    res = f.readlines
    f.close

    res.shift(2)
    res.pop

    res.each{|mc|
      vmName =  (mc.gsub(/\s+/m, ' ').gsub(/^\s+|\s+$/m, '').split(" "))[1]
      state  =  (mc.gsub(/\s+/m, ' ').gsub(/^\s+|\s+$/m, '').split(" "))[2]

#            puts "State   #{state}"
#            puts "vmName  #{vmName}"

      if vmName == @name
        puts "FATAL ERROR: Machine >#{@name}< exists"
        status = true
        break
      end
    }
    status
  end

  def machineRunning?
  end

  def rmVM
    puts "Removing VM"

    cmd = "virsh undefine #{@name}"

    if dryRun
      print "Would Run\n\t"
      puts cmd
    else
      system( cmd )
    end
  end

  def mkVM
    exit if machineExists?
    cmd =  "virt-install --connect qemu:///system --name #{@name} --ram 2048 --vcpus 4 --graphics vnc --cdrom #{@cdrom} --boot cdrom --network network:default --os-variant=ubuntuprecise "
    @disks.each{|disk|
      cmd << " --disk path=" << disk.mkPath
    }

    if @dryRun
      print "Would Run\n\t"
      puts cmd
    else
      system(cmd)
    end

  end

end