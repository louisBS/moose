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
  nx = 400
  ny = 40
  xmin = 0
  xmax = 100
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
    type = FunctionIC
    variable = C_Mn
    function = initial_Mn #'if(x<90, 7.1445,7.1445-7.1445/10*(x-90))' #start at 20 hr, already some Mn left #if(x<90, 7.1445,7.1445-4.8245/10*(x-90))
  [../]

  [./ic_Cr]
    type = FunctionIC
    variable = C_Cr
    function = initial_Cr #'if(x<90, 7.1445,7.1445-7.1445/10*(x-90))' #start at 20 hr, already some Mn left #if(x<90, 7.1445,7.1445-4.8245/10*(x-90))
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

[Materials]
  [./diffusivity_Mn]
    type = GenericConstantMaterial
    prop_names = Mn_diffusion_coefficient
    prop_values = 0.0304   # [µm²/hr]
  [../]
  [./diffusivity_Cr]
    type = GenericConstantMaterial
    prop_names = Cr_diffusion_coefficient
    prop_values = 0.1   # [µm²/hr]
  [../]
[]

[Functions]
  [./initial_Mn]
     type = ParsedFunction
     value = 2.15+(7.15-2.15)*erf(0.6408*x)
   [../]
   [./initial_Cr]
      type = ParsedFunction
      value = 15.52+(18.06-15.52)*erf(1.246*x)
    [../]
[]

[BCs]
  [./right_Mn]
    type = NeumannBC
    variable = C_Mn
    value = 0
    boundary = right
  [../]

#  [./left_Mn] # Fixed flux (arbitrary value)
#    type = NeumannBC
#    variable = C_Mn
#    value = -3e-2
#    boundary = left
#  [../]

#  [./left_Mn] # Flux = derivative of the total Mn content
#    type = PostprocessorNeumannBC
#    variable = C_Mn
#    boundary = left
#    postprocessor = derivative_Mn_in_metal
#  [../]

#  [./left_Mn] # vayring C^Mn_M/O given by (wrong) formula above
#    type = FunctionDirichletBC
#    variable = C_Mn
#    boundary = left
#    function = m_o_function
#  [../]

#  [./left_Mn] # Fixed concentration
#    type = DirichletBC
#    variable = C_Mn
#    value = 2.15
#    boundary = left
#  [../]

  [./right_Cr]
    type = NeumannBC
    variable = C_Cr
    value = 0
    boundary = right
  [../]

  #[./left_Cr] # Fixed concentration
    #  type = DirichletBC
    #  variable = C_Cr
    #  value = 15.52
    #  boundary = left
    #[../]

  [./left_Cr_flux] # Flux Cr = 2*flux Mn
    type = PostprocessorNeumannBC
    variable = C_Cr
    boundary = left
    postprocessor = two_Mn_flux
  [../]

  [./left_Mn_Robin_C]
    type = PostprocessorDirichletBC
    variable = C_Mn
    boundary = left
    postprocessor = Robin_Mn_concentration
  [../]

#  [./left_Mn_Robin_flux]
#    type = PostprocessorNeumannBC
#    variable = C_Mn
#    boundary = left
#    postprocessor = Robin_Mn_flux
#  [../]
[]

[Postprocessors]

  [./leaving_Mn_flux] #[(at/nm³/µm)*µm²/hr = at/nm³*µm/hr]
    type = SideFluxAverage
    boundary = left
    diffusivity = 'Mn_diffusion_coefficient'
    variable = C_Mn
    execute_on = 'linear nonlinear timestep_begin timestep_end'
  [../]

  [./two_Mn_flux] #[(at/nm³/µm)*µm²/hr = at/nm³*µm/hr]
    type = ScalePostprocessor
    value = leaving_Mn_flux
    scaling_factor = -2
    execute_on = 'linear nonlinear timestep_begin timestep_end'
  [../]

  [./Robin_Mn_concentration] #[at/nm³]
    type = ScalePostprocessor
    value = leaving_Mn_flux
    scaling_factor = 30 #1/(D*sigma)
    execute_on = 'linear nonlinear timestep_begin timestep_end'
  [../]

  [./C_Mn_MO]
    type = SideAverageValue
    variable = C_Mn
    boundary = left
    execute_on = 'linear nonlinear timestep_begin timestep_end'
  [../]

  [./Robin_Mn_flux] #[at/nm³]
    type = ScalePostprocessor
    value = C_Mn_MO
    scaling_factor = 3.3e-2 #D*sigma
    execute_on = 'linear nonlinear timestep_begin timestep_end'
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
  [../]

  [./avg_Mn_in_metal] #[at/nm³]
    type = ElementAverageValue #IntegralVariablePostprocessor
    variable = C_Mn
    execute_on = 'linear nonlinear timestep_begin timestep_end'
  [../]

  [./Mn_in_metal] #[at/nm³*µm]
    type = ScalePostprocessor
    value = avg_Mn_in_metal
    scaling_factor = 100 #xmax [µm]
    execute_on = 'linear nonlinear timestep_begin timestep_end'
  [../]

  [./change_Mn_in_metal] #[at/nm³*µm]
    type = ChangeOverTimestepPostprocessor
    postprocessor = Mn_in_metal
    execute_on = 'linear nonlinear timestep_begin timestep_end'
  [../]

  [./derivative_Mn_in_metal] #[at/nm³*µm/hr]
    type = ScalePostprocessor
    value = change_Mn_in_metal
    scaling_factor = 0.1    #1/dt [/hr]
    execute_on = 'linear nonlinear timestep_begin timestep_end'
  [../]

  [./avg_Cr_in_metal] #[at/nm³]
    type = ElementAverageValue #IntegralVariablePostprocessor
    variable = C_Cr
    execute_on = 'linear nonlinear timestep_begin timestep_end'
  [../]

  [./Cr_in_metal] #[at/nm³*µm]
    type = ScalePostprocessor
    value = avg_Cr_in_metal
    scaling_factor = 100 #xmax [µm]
    execute_on = 'linear nonlinear timestep_begin timestep_end'
  [../]

  [./change_Cr_in_metal] #[at/nm³*µm]
    type = ChangeOverTimestepPostprocessor
    postprocessor = Cr_in_metal
    execute_on = 'linear nonlinear timestep_begin timestep_end'
  [../]

  [./derivative_Cr_in_metal] #[at/nm³*µm/hr]
    type = ScalePostprocessor
    value = change_Cr_in_metal
    scaling_factor = 0.1    #1/dt [/hr]
    execute_on = 'linear nonlinear timestep_begin timestep_end'
  [../]

  [./minus_Cr_flux] #[(at/nm³/µm)*µm²/hr = at/nm³*µm/hr]
    type = ScalePostprocessor
    value = leaving_Cr_flux
    scaling_factor = -1
    execute_on = 'linear nonlinear timestep_begin timestep_end'
  [../]

  [./oxide_growth_rate] #[µm/hr]
    type = ScalePostprocessor
    value = leaving_Mn_flux  #derivative_Mn_in_metal
    scaling_factor = 0.0751     #oxide molecular volume in nm³
  [../]

  [./delta_oxide] #[µm]
    type = TotalVariableValue
    value = oxide_growth_rate
  [../]

  [./pos_bcc]
    type = FindValueOnLine
    target = 3.80
    v = C_Mn
    start_point = '0 5 0'
    end_point = '100 5 0'
    tol = 1e-3
    execute_on = 'timestep_end'
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

  start_time = 10
  dt = 10
  num_steps = 99
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
