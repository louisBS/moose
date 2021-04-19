//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#include "XFEMC4VelocityZero.h"

registerMooseObject("XFEMApp", XFEMC4VelocityZero);

template <>
InputParameters
validParams<XFEMC4VelocityZero>()
{
  InputParameters params = validParams<XFEMMovingInterfaceVelocityBase>();
  params.addClassDescription(
      "Velocity object for fixed 2D interfaces (zero velocity)");
  return params;
}

XFEMC4VelocityZero::XFEMC4VelocityZero(const InputParameters & parameters)
  : XFEMMovingInterfaceVelocityBase(parameters)
{
}

Real
XFEMC4VelocityZero::computeMovingInterfaceVelocity(unsigned int point_id) const
{
  return 0.0;
}
