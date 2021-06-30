# Input file for an oxide growing outward on top of a steel 21-2N sample.
# The oxide is not meshed, just the metal.
# The oxide growth rate is computed using the Mn and Cr fluxes at the metal/oxide interface
# The variables are the Mn and Cr atomic densities [at/nm^3]
# The length unit is the micrometer. The time unit is the hour.
# Homogeneous T=700C for now.
# This file is for the planar 2D case (monodirectional corrosion)

[GlobalParams]
  order = FIRST
  family = LAGRANGE
[]


[Mesh]
  type = GeneratedMesh
  dim = 2
  nx = 240
  ny = 40
  xmin = 0
  xmax = 60
  ymin = 0
  ymax = 10
  elem_type = QUAD4
[]

[Variables]
  [./C_Mn]
  [../]
  [./C_Cr]
  [../]
[]

[ICs]
  [./ic_Mn]
    type = ConstantIC
    variable = C_Mn
    value = 7.1743              #Nominal Mn concentration in the alloy [at/nm^3]
  [../]

  [./ic_Cr]
    type = ConstantIC
    variable = C_Cr
    value = 18.148              #Nominal Cr concentration in the alloy [at/nm^3]
  [../]
[]

[Kernels]
  [./diff_Mn]
    type = MatDiffusion
    variable = C_Mn
    diffusivity = 'Mn_diffusion_coefficient'
  [../]
  [./diff_Cr]
    type = MatDiffusion
    variable = C_Cr
    diffusivity = 'Cr_diffusion_coefficient'
  [../]
  [./time_derivative_Mn]
    type = TimeDerivative
    variable = C_Mn
  [../]
  [./time_derivative_Cr]
    type = TimeDerivative
    variable = C_Cr
  [../]
[]

[Functions]
  [./D_Mn_func]
    type = ParsedFunction
    value = D_0/sqrt(1+a*t)       # Time evolution of diffusion coefficient linked to grain growth
    vars = 'D_0 a'                # D_0 [um^2/hr]; a [/hr]
    vals = '3.335e-2 3.844e-3'
  [../]

  [./D_Cr_func]
    type = ParsedFunction
    value = D_0/sqrt(1+a*t)
    vars = 'D_0 a'
    vals = '1.309e-2 3.844e-3'
  [../]

  [Robin_Mn_flux_func]             #Robin BC computes the flux from the interface concentration
    type = ParsedFunction
    value = -sigma*D_0/(1+a*sqrt(t))*(C_MO-C_eq)
    vars = 'sigma D_0 a C_MO C_eq' # sigma [/um]
    vals = '1.10 3.335e-2 3.844e-3 C_Mn_MO 0'
  []

  [Robin_Cr_flux_func]
    type = ParsedFunction
    value = -sigma*D_0/(1+a*sqrt(t))*(C_MO-C_eq)
    vars = 'sigma D_0 a C_MO C_eq'
    vals = '0.36 1.309e-2 3.844e-3 C_Cr_MO 0'
  []
[]

[Materials]
  [./diffusivity_Mn]
    type = GenericFunctionMaterial
    prop_names = Mn_diffusion_coefficient
    prop_values = D_Mn_func  # [µm²/hr]
  [../]
  [./diffusivity_Cr]
    type = GenericFunctionMaterial
    prop_names = Cr_diffusion_coefficient
    prop_values = D_Cr_func # [µm²/hr]
  [../]
[]

[BCs]
# Right boundary = 60 um into the alloy = infinity
  [./right_Mn]
    type = DirichletBC
    variable = C_Mn
    value = 7.1743      #Nominal Mn concentration in the alloy [at/nm^3]
    boundary = right
  [../]

  [./right_Cr]
    type = DirichletBC
    variable = C_Cr
    value = 18.148
    boundary = right
  [../]

# Left boundary = x=0 = alloy/oxide interface
  [./left_Mn_Robin_flux]
    type = PostprocessorNeumannBC
    variable = C_Mn
    boundary = left
    postprocessor = Robin_Mn_flux
  [../]

  [./left_Cr_Robin_flux]
    type = PostprocessorNeumannBC
    variable = C_Cr
    boundary = left
    postprocessor = Robin_Cr_flux
  [../]
[]

[Postprocessors]

  [./C_Mn_MO]
    type = SideAverageValue
    variable = C_Mn
    boundary = left
    execute_on = 'linear nonlinear timestep_begin timestep_end'
    outputs = 'none'
  [../]

  [./Robin_Mn_flux] #[at/nm³]
    type = FunctionValuePostprocessor
    function = Robin_Mn_flux_func
    execute_on = 'linear nonlinear timestep_begin timestep_end'
    outputs = 'none'
  [../]

  [./leaving_Mn_flux] #[(at/nm³/µm)*µm²/hr = at/nm³*µm/hr]
    type = SideFluxAverage
    boundary = left
    diffusivity = 'Mn_diffusion_coefficient'
    variable = C_Mn
    execute_on = 'linear nonlinear timestep_begin timestep_end'
    outputs = 'none'
  [../]

  [./C_Cr_MO]
    type = SideAverageValue
    variable = C_Cr
    boundary = left
    execute_on = 'linear nonlinear timestep_begin timestep_end'
    outputs = 'none'
  [../]

  [./Robin_Cr_flux] #[at/nm³]
    type = FunctionValuePostprocessor
    function = Robin_Cr_flux_func
    execute_on = 'linear nonlinear timestep_begin timestep_end'
    outputs = 'none'
  [../]

  [./leaving_Cr_flux] #[(at/nm³/µm)*µm²/hr = at/nm³*µm/hr]
    type = SideFluxAverage
    boundary = left
    diffusivity = 'Cr_diffusion_coefficient'
    variable = C_Cr
    execute_on = 'linear nonlinear timestep_begin timestep_end'
    outputs = 'none'
  [../]

  [./spinel_growth_rate] #[µm/hr]
    type = ScalePostprocessor
    value = leaving_Cr_flux
    scaling_factor = 0.0375  #0.0375 = 1/2 (for MnCr2O4) * spinel oxide molecular volume in nm³
    outputs = 'none'
  [../]

  [./delta_spinel] #Total spinel oxide thickness [µm]
    type = TotalVariableValue
    value = spinel_growth_rate
  [../]

  [./Mn_flux_in_spinel] #[at/nm³*µm/hr]  # Mn flux allocated to spinel growth = half the Cr flux
    type = ScalePostprocessor
    value = leaving_Cr_flux
    scaling_factor = 0.5  # 1/2 for MnCr2O4
    outputs = 'none'
  [../]

  [./Mn_flux_in_Mn_oxide] #[at/nm³*µm/hr] # Mn flux allocated to Mn oxide growth = rest of the Mn flux
    type = DifferencePostprocessor
    value1 = leaving_Mn_flux
    value2 = Mn_flux_in_spinel
    outputs = 'none'
  [../]

  [./Mn_oxide_growth_rate] #[µm/hr]
    type = ScalePostprocessor
    value = Mn_flux_in_Mn_oxide
    scaling_factor = 0.0261    # 1/3 (for Mn-3-O4) * Mn oxide molecular volume in nm³
    outputs = 'none'
  [../]

  [./delta_Mn_ox] #Total Mn oxide thickness [µm]
    type = TotalVariableValue
    value = Mn_oxide_growth_rate
  [../]

  [./delta_total] #Total oxide thickness [µm]
    type = LinearCombinationPostprocessor
    pp_names = 'delta_spinel delta_Mn_ox'
    pp_coefs = '1   1'
    b = 0
  [../]

[]

[VectorPostprocessors]

  [./Mn_profile]
    type = LineValueSampler
    start_point = '0 5 0'
    end_point = '60 5 0'
    sort_by = x
    num_points = 241
    outputs = csv
    variable = 'C_Mn'
  [../]

  [./Cr_profile]
    type = LineValueSampler
    start_point = '0 5 0'
    end_point = '60 5 0'
    sort_by = x
    num_points = 241
    outputs = csv
    variable = 'C_Cr'
  [../]

[]

[Executioner]
  type = Transient
  solve_type = 'PJFNK'
  petsc_options_iname = '-pc_type'
  petsc_options_value = 'lu'
  line_search = 'none'

  l_tol = 1e-3
  nl_max_its = 15
  nl_rel_tol = 1e-7
  nl_abs_tol = 1e-7

  start_time = -10
  dt = 10
  num_steps = 201
[]


[Outputs]
  execute_on = timestep_end
  exodus = true
  [./console]
    type = Console
    output_linear = true
  [../]
  csv = true
  perf_graph = true
[]
