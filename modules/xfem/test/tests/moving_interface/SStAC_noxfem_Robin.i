# Input file for an oxide growing outward on top of a steel 21-2N sample.
# The oxide is not modelled, just the metal.
# The oxide growth rate is computed using the Mn gradient at the metal/oxide interface
# The variable is the Mn atomic density [at/nm^3]
# The length unit is the micrometer. The time unit is the hour.
# Homogeneous T=700C for now.

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
    value = 7.1743
  [../]

  [./ic_Cr]
    type = ConstantIC
    variable = C_Cr
    value = 18.148
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
    value = D_0/sqrt(1+a*t)
    vars = 'D_0 a'
    vals = '3.335e-2 3.844e-3'
  [../]

  [./D_Cr_func]
    type = ParsedFunction
    value = D_0/sqrt(1+a*t)
    vars = 'D_0 a'
    vals = '1.309e-2 3.844e-3' #'1.208e-2 3.844e-3'
  [../]

  [Robin_Mn_flux_func]
    type = ParsedFunction
    value = -sigma*D_0/(1+a*sqrt(t))*(C_MO-C_eq)
    vars = 'sigma D_0 a C_MO C_eq'
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
    prop_values = D_Cr_func #0.011 # [µm²/hr]
  [../]
[]

[BCs]
  [./right_Mn]
    type = DirichletBC
    variable = C_Mn
    value = 7.1743
    boundary = right
  [../]

#  [./left_Mn] # Fixed concentration
#    type = DirichletBC
#    variable = C_Mn
#    value = 2.15
#    boundary = left
#  [../]

  [./right_Cr]
    type = DirichletBC
    variable = C_Cr
    value = 18.148
    boundary = right
  [../]

  #[./left_Cr] # Fixed concentration
    #  type = DirichletBC
    #  variable = C_Cr
    #  value = 15.52
    #  boundary = left
    #[../]

#  [./left_Cr_flux] # Flux Cr = 2*flux Mn
#    type = PostprocessorNeumannBC
#    variable = C_Cr
#    boundary = left
#    postprocessor = two_Mn_flux
#  [../]

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

  [./leaving_Mn_flux] #[(at/nm³/µm)*µm²/hr = at/nm³*µm/hr]
    type = SideFluxAverage
    boundary = left
    diffusivity = 'Mn_diffusion_coefficient'
    variable = C_Mn
    execute_on = 'linear nonlinear timestep_begin timestep_end'
  [../]

#  [./two_Mn_flux] #[(at/nm³/µm)*µm²/hr = at/nm³*µm/hr]
#    type = ScalePostprocessor
#    value = leaving_Mn_flux
#    scaling_factor = -2
#    execute_on = 'linear nonlinear timestep_begin timestep_end'
#    outputs = 'none'
#  [../]

  [./C_Mn_MO]
    type = SideAverageValue
    variable = C_Mn
    boundary = left
    execute_on = 'linear nonlinear timestep_begin timestep_end'
  [../]

#  [./Robin_Mn_flux] #[at/nm³]
#    type = ScalePostprocessor
#    value = C_Mn_MO
#    scaling_factor = -0.0354 #D*sigma [µm/hr]
#    execute_on = 'linear nonlinear timestep_begin timestep_end'
#    outputs = 'none'
#  [../]

  [./Robin_Mn_flux] #[at/nm³]
    type = FunctionValuePostprocessor
    function = Robin_Mn_flux_func
    execute_on = 'linear nonlinear timestep_begin timestep_end'
    #outputs = 'none'
  [../]

  [./C_Cr_MO]
    type = SideAverageValue
    variable = C_Cr
    boundary = left
    execute_on = 'linear nonlinear timestep_begin timestep_end'
  [../]

#  [./Robin_Cr_flux] #[at/nm³]
#    type = ScalePostprocessor
#    value = C_Cr_MO
#    scaling_factor = -0.00535 #D*sigma [µm/hr]
#    execute_on = 'linear nonlinear timestep_begin timestep_end'
#    outputs = 'none'
#  [../]

  [./Robin_Cr_flux] #[at/nm³]
    type = FunctionValuePostprocessor
    function = Robin_Cr_flux_func
    execute_on = 'linear nonlinear timestep_begin timestep_end'
    #outputs = 'none'
  [../]

  [./leaving_Cr_flux] #[(at/nm³/µm)*µm²/hr = at/nm³*µm/hr]
    type = SideFluxAverage
    boundary = left
    diffusivity = 'Cr_diffusion_coefficient'
    variable = C_Cr
    execute_on = 'linear nonlinear timestep_begin timestep_end'
  [../]

  [./minus_Mn_flux] #[(at/nm³/µm)*µm²/hr = at/nm³*µm/hr]
    type = ScalePostprocessor
    value = leaving_Mn_flux
    scaling_factor = -1
    execute_on = 'linear nonlinear timestep_begin timestep_end'
    outputs = 'none'
  [../]

  [./avg_Mn_in_metal] #[at/nm³]
    type = ElementAverageValue #IntegralVariablePostprocessor
    variable = C_Mn
    execute_on = 'linear nonlinear timestep_begin timestep_end'
    outputs = 'none'
  [../]

  [./Mn_in_metal] #[at/nm³*µm]
    type = ScalePostprocessor
    value = avg_Mn_in_metal
    scaling_factor = 60 #xmax [µm]
    execute_on = 'linear nonlinear timestep_begin timestep_end'
    outputs = 'none'
  [../]

  [./change_Mn_in_metal] #[at/nm³*µm]
    type = ChangeOverTimestepPostprocessor
    postprocessor = Mn_in_metal
    execute_on = 'linear nonlinear timestep_begin timestep_end'
    outputs = 'none'
  [../]

  [./derivative_Mn_in_metal] #[at/nm³*µm/hr]
    type = ScalePostprocessor
    value = change_Mn_in_metal
    scaling_factor = 0.1    #1/dt [/hr]
    execute_on = 'linear nonlinear timestep_begin timestep_end'
    outputs = 'none'
  [../]

  [./avg_Cr_in_metal] #[at/nm³]
    type = ElementAverageValue #IntegralVariablePostprocessor
    variable = C_Cr
    execute_on = 'linear nonlinear timestep_begin timestep_end'
    outputs = 'none'
  [../]

  [./Cr_in_metal] #[at/nm³*µm]
    type = ScalePostprocessor
    value = avg_Cr_in_metal
    scaling_factor = 60 #xmax [µm]
    execute_on = 'linear nonlinear timestep_begin timestep_end'
    outputs = 'none'
  [../]

  [./change_Cr_in_metal] #[at/nm³*µm]
    type = ChangeOverTimestepPostprocessor
    postprocessor = Cr_in_metal
    execute_on = 'linear nonlinear timestep_begin timestep_end'
    outputs = 'none'
  [../]

  [./derivative_Cr_in_metal] #[at/nm³*µm/hr]
    type = ScalePostprocessor
    value = change_Cr_in_metal
    scaling_factor = 0.1    #1/dt [/hr]
    execute_on = 'linear nonlinear timestep_begin timestep_end'
    outputs = 'none'
  [../]

  [./minus_Cr_flux] #[(at/nm³/µm)*µm²/hr = at/nm³*µm/hr]
    type = ScalePostprocessor
    value = leaving_Cr_flux
    scaling_factor = -1
    execute_on = 'linear nonlinear timestep_begin timestep_end'
    outputs = 'none'
  [../]

  [./spinel_growth_rate] #[µm/hr]
    type = ScalePostprocessor
    value = leaving_Cr_flux
    scaling_factor = 0.0375  #1/2.2 * V_spinel=0.0341    #0.0375 = 1/2 (for MnCr-2-O4) * spinel oxide molecular volume in nm³
    outputs = 'none'
  [../]

  [./delta_spinel] #[µm]
    type = TotalVariableValue
    value = spinel_growth_rate
  [../]

  [./Mn_flux_in_spinel] #[at/nm³*µm/hr]
    type = ScalePostprocessor
    value = leaving_Cr_flux
    scaling_factor = 0.5  # 1/2 for Mn-1-Cr-2-O4
    outputs = 'none'
  [../]

  [./Mn_flux_in_Mn_oxide] #[at/nm³*µm/hr]
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

  [./delta_Mn_ox] #[µm]
    type = TotalVariableValue
    value = Mn_oxide_growth_rate
  [../]

  [./delta_total]
    type = LinearCombinationPostprocessor
    pp_names = 'delta_spinel delta_Mn_ox'
    pp_coefs = '1   1'
    b = 0
  [../]

#  [./pos_bcc]
#    type = FindValueOnLine
#    target = 3.80
#    v = C_Mn
#    start_point = '0 5 0'
#    end_point = '100 5 0'
#    tol = 1e-3
#    execute_on = 'timestep_end'
#  [../]
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
