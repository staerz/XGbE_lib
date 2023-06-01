-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;

------------------------------<-    80 chars    ->------------------------------
--! @file
--! @brief Interfaces context of the project
--! @details Contains the full list of interfaces,
--! inherits from constants.vhd.
--! @author Steffen Stärz <steffen.staerz@cern.ch>
--------------------------------------------------------------------------------

--! @cond
context interfaces is

  library IEEE;
    context IEEE.IEEE_STD_CONTEXT;

  library PoC;
    use PoC.utils.all;

  library fpga;
    --context fpga.constants;
    use fpga.fpga_if.all;

end context interfaces;

--! @endcond
