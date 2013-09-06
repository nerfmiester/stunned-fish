class Listdisks

  def initilize  virtualMachineName
    @virtualMachine=IO.popen ("virsh dumpxml #{virtualMachineName} | grep source dev")
    @vmLines=@virtualMachine.readlines
  end

  def returnVirtualMachineDisks
    @disks = Array.new
    @vmLines.each do  |line|
      disk=line[0..-5].split("'")[1]
      qq=ff.split('/')
      aa=qq[1]
      bb=qq[2]
      cc=qq[3]
      @disks.concat(["#{aa}/#{bb}/new#{cc}"])
    end
    return @disks
  end

end