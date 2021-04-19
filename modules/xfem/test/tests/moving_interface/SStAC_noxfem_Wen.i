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
  nx = 100
  ny = 10
  xmin = 0
  xmax = 100
  ymin = 0
  ymax = 10
  elem_type = QUAD4
[]

[Variables]
  [./C_Mn]
  [../]
[]

[ICs]
  [./ic_Mn]
    type = FunctionIC
    variable = C_Mn
    function = 'if(x<90, 7.1445,7.1445-4.8245/10*(x-90))' #start at 20 hr, already some Mn left
  [../]
[]

[Kernels]
  [./diff]
    type = MatDiffusion
    variable = C_Mn
    diffusivity = 'steel_diffusion_coefficient'
  [../]
  [./time]
    type = TimeDerivative
    variable = C_Mn
  [../]
[]

[Materials]
  [./diffusivity_steel]
    type = GenericConstantMaterial
    prop_names = steel_diffusion_coefficient
    prop_values = 0.036   # [µm²/hr]
  [../]
[]

[Functions]
#  [./m_o_function] #Function giving the evolution of C^Mn_M/O over time (wrong)
#     type = ParsedFunction
#     value = N0*erf(x_MO/2/sqrt(D*t))
#     vars = 'N0 x_MO D'
#     vals = '2.32 30 1'
#   [../]
[]

[BCs]
  [./left_Mn]
    type = NeumannBC
    variable = C_Mn
    value = 0
    boundary = left
  [../]

  # [./right_Mn] # Fixed flux (arbitrary value)
  #   type = NeumannBC
  #   variable = C_Mn
  #   value = -3e-2
  #   boundary = right
  # [../]

 [./right_Mn] # Flux = derivative of the total Mn content
   type = PostprocessorNeumannBC
   variable = C_Mn
   boundary = right
   postprocessor = derivative_Mn_in_metal
 [../]

#  [./right_Mn] # vayring C^Mn_M/O given by (wrong) formula above
#    type = FunctionDirichletBC
#    variable = C_Mn
#    boundary = right
#    function = m_o_function
#  [../]

#  [./right_u] # Fixed concentration =0
#    type = DirichletBC
#    variable = C_Mn
#    value = 0
#    boundary = right
#  [../]
[]

[Postprocessors]

  [./leaving_Mn_flux] #[(at/nm³/µm)*µm²/hr = at/nm³*µm/hr]
    type = SideFluxAverage
    boundary = right
    diffusivity = 'steel_diffusion_coefficient'
    variable = C_Mn
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

  # [./Mn_in_metal] #[at/nm³*µm]
  #   type = ElementIntegralVariablePostprocessor
  #   variable = C_Mn
  # [../]

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

  [./oxide_growth_rate] #[µm/hr]
    type = ScalePostprocessor
    value = leaving_Mn_flux
    scaling_factor = 0.0751     #oxide molecular volume in nm³
  [../]

  [./delta_oxide] #[µm]
    type = TotalVariableValue
    value = oxide_growth_rate
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
